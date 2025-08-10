import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {VertexAI} from "@google-cloud/vertexai";

admin.initializeApp();
const firestore = admin.firestore();

const projectId = process.env.GCLOUD_PROJECT;
if (!projectId) {
  throw new Error("GCLOUD_PROJECT environment variable not set.");
}

const vertexAI = new VertexAI({project: projectId, location: "us-central1"});
const generativeModel = vertexAI.getGenerativeModel({
  model: "gemini-2.5-flash",
});

// FIX: Update the function signature to use the new 'request' object
export const generateWeeklyInsight = functions.https.onCall(
  async (request) => {
    // 1. Authenticate the user using request.auth
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to request an insight.",
      );
    }
    const userId = request.auth.uid;

    // 2. Fetch the last 7 days of data from Firestore
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const workoutLogsPromise = firestore.collection("users").doc(userId)
      .collection("workoutLogs").where("date", ">=", sevenDaysAgo).get();
    const nutritionLogsPromise = firestore.collection("users").doc(userId)
      .collection("nutritionLogs")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();

    const [workoutSnapshots, nutritionSnapshots] = await Promise.all([
      workoutLogsPromise,
      nutritionLogsPromise,
    ]);

    const workoutData = workoutSnapshots.docs.map((doc) => doc.data());
    const nutritionData = nutritionSnapshots.docs.map((doc) => doc.data());

    if (workoutData.length === 0 && nutritionData.length === 0) {
      return {message: "No data found for the last 7 days."};
    }

    // 3. Engineer the prompt for the AI Coach
    const prompt = `
        You are an expert fitness coach. Analyze the following data for the
        last 7 days and provide a concise, encouraging summary in markdown
        with three sections: "Workout Consistency", "Nutrition Highlights",
        and "Recommendations for Next Week".

        Workout Logs: ${JSON.stringify(workoutData)}
        Nutrition Logs: ${JSON.stringify(nutritionData)}
      `;

    // 4. Call the Gemini AI model
    let aiResponseText: string;
    try {
      const resp = await generativeModel.generateContent(prompt);
      const firstPart = resp.response.candidates?.[0].content.parts[0];
      aiResponseText = firstPart?.text ??
          "I was unable to generate insights at this time.";
    } catch (error) {
      console.error("Error calling AI model:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate AI insight.",
      );
    }

    // 5. Save the insight back to Firestore
    const insightDoc = {
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      summaryText: aiResponseText,
      type: "weekly",
    };

    await firestore.collection("users").doc(userId)
      .collection("insights").add(insightDoc);

    return {message: "Insight generated successfully!"};
  },
);
// In functions/src/index.ts

export const suggestNutritionGoals = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to request suggestions.",
      );
    }

    const {
      primaryGoal,
      biologicalSex,
      weightKg,
      heightCm,
      activityLevel,
    } = request.data;
    if (
      !primaryGoal || !biologicalSex || !weightKg || !heightCm || !activityLevel
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required profile data.",
      );
    }

    const prompt = `
        You are an expert nutritionist. Calculate daily nutrition goals
        (calories, protein, carbs, fat) based on user data.

        User Data:
        - Goal: ${primaryGoal}
        - Sex: ${biologicalSex}
        - Weight: ${weightKg} kg
        - Height: ${heightCm} cm
        - Activity: ${activityLevel}

        Calculation Steps:
        1. Use Mifflin-St Jeor for BMR.
        2. Use TDEE multipliers (Sedentary: 1.2, Lightly: 1.375, etc.).
        3. Adjust TDEE: -500 kcal for loss, +300 kcal for gain.
        4. Macros: Protein 1.8g/kg, Fat 25% of kcal, Carbs for remainder.
        5. (P/C = 4 kcal/g, F = 9 kcal/g).

        IMPORTANT: Respond with ONLY a valid JSON object. All values must be
        rounded to a whole number.
        {
          "targetCalories": number,
          "targetProtein": number,
          "targetCarbs": number,
          "targetFat": number
        }
      `;

    try {
      const resp = await generativeModel.generateContent(prompt);
      const jsonString = resp.response.candidates?.[0]
        .content.parts[0].text ?? "{}";

      const goals = JSON.parse(jsonString);
      return goals;
    } catch (error) {
      console.error("Error calling AI model for nutrition goals:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate AI nutrition goals.",
      );
    }
  },
);

// In functions/src/index.ts

export const generateMealInsight = functions.https.onCall(
  async (request) => {
    // 1. Authenticate the user using the modern 'request' object
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in.",
      );
    }

    // 2. Validate incoming data from request.data
    const {primaryGoal, meal} = request.data;
    if (!primaryGoal || !meal) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required profile goal or meal data.",
      );
    }

    // 3. Engineer the prompt for the AI Coach
    const prompt = `
        You are a positive and encouraging fitness coach.
        A user is logging a meal. Their primary goal is "${primaryGoal}".
        The meal they just ate has the following macros:
        - Calories: ${meal.calories}
        - Protein: ${meal.protein}g
        - Carbs: ${meal.carbs}g
        - Fat: ${meal.fat}g

        Your task is to write a single, short, encouraging sentence
        (under 20 words) that positively frames how this meal
        impacts the user's primary goal.

        Example 1:
        Goal: "Gain Muscle", Meal has high protein.
        Response: "Great choice! This high-protein meal is perfect for
        helping you build muscle."

        Example 2:
        Goal: "Lose Weight", Meal is low in calories.
        Response: "Excellent! A light and satisfying meal that keeps you
        perfectly on track with your calorie target."

        Respond with ONLY the single sentence and nothing else.
      `;

    // 4. Call the Gemini AI model
    try {
      const resp = await generativeModel.generateContent(prompt);
      const insightText = resp.response.candidates?.[0]
        .content.parts[0].text ?? "";

      // 5. Return the insight to the app
      return {insightText: insightText.trim()};
    } catch (error) {
      console.error("Error calling AI model for meal insight:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate AI meal insight.",
      );
    }
  },
);

// We need to define the structure of our WorkoutDay for TypeScript
interface WorkoutDay {
  dayName: string;
  exercises: any[]; // Using 'any' for simplicity for now
}

export const aiAssistant = functions.https.onCall(
    async (request) => {
      if (!request.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in.",
        );
      }
      const userId = request.auth.uid;
      const userPrompt = request.data.prompt;

      if (!userPrompt) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "A prompt is required.",
        );
      }

      // 1. Define the "tools" the AI can use.
      const tools = [{
        functionDeclarations: [{
          name: "createNewWorkoutProgram",
          description: "Creates a new, empty workout program for the user.",
          parameters: {
            type: "OBJECT",
            properties: {
              name: {
                type: "STRING",
                description: "The name of the workout program.",
              },
              days: {
                type: "NUMBER",
                description: "The number of days in the program.",
              },
            },
            required: ["name", "days"],
          },
        }],
      }];

      try {
        const chat = generativeModel.startChat({tools});
        const result = await chat.sendMessage(userPrompt);
        const call = result.response.functionCalls()?.[0];

        if (call) {
          const {name, days} = call.args;

          // 2. Execute the function the AI wants to call.
          const defaultDays: WorkoutDay[] = Array.from({length: days},
              (_, i) => ({
                dayName: `Day ${i + 1}`,
                exercises: [],
              }));
          
          const newProgram = {name, days: defaultDays};
          
          await firestore.collection("users").doc(userId)
              .collection("workoutPrograms").add(newProgram);

          // 3. Send the result back to the AI to get a final response.
          const finalResult = await chat.sendMessage([{
            functionResponse: {
              name: "createNewWorkoutProgram",
              response: {name, success: true},
            },
          }]);
          
          const responseText =
            finalResult.response.candidates?.[0].content.parts[0].text ?? "";
          return {responseText: responseText.trim()};
        } else {
          // If the AI didn't call a function, return its text response
          const responseText =
            result.response.candidates?.[0].content.parts[0].text ?? "";
          return {responseText: responseText.trim()};
        }
      } catch (error) {
        console.error("Error in AI Assistant:", error);
        throw new functions.https.HttpsError(
            "internal",
            "The AI assistant encountered an error.",
        );
      }
    },
);
