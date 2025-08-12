import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  VertexAI,
  HarmCategory,
  HarmBlockThreshold,
  Tool,
  FunctionDeclarationSchema,
} from "@google-cloud/vertexai";

admin.initializeApp();
const firestore = admin.firestore();

const projectId = process.env.GCLOUD_PROJECT;
if (!projectId) {
  throw new Error("GCLOUD_PROJECT environment variable not set.");
}

const vertexAI = new VertexAI({project: projectId, location: "us-central1"});

const generativeModel = vertexAI.getGenerativeModel({
  model: "gemini-2.5-flash",
  safetySettings: [
    {
      category: HarmCategory.HARM_CATEGORY_HARASSMENT,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
    },
  ],
});

// == HELPER INTERFACES ==
interface WorkoutDay {
  dayName: string;
  exercises: { name: string; sets: number; reps: number }[];
}

// == FUNCTIONS ==

export const generateWeeklyInsight = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "You must be logged in.");
    }
    const userId = request.auth.uid;
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    try {
      const workoutLogsPromise = firestore
        .collection("userProfiles").doc(userId)
        .collection("workoutLogs").where("date", ">=", sevenDaysAgo).get();
      const nutritionLogsPromise = firestore
        .collection("userProfiles").doc(userId)
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

      const prompt = `
        You are an expert fitness coach. Analyze the following data for the
        last 7 days and provide a concise, encouraging summary in markdown
        with three sections: "Workout Consistency", "Nutrition Highlights",
        and "Recommendations for Next Week".
        Workout Logs: ${JSON.stringify(workoutData)}
        Nutrition Logs: ${JSON.stringify(nutritionData)}
      `;

      const result = await generativeModel.generateContent(prompt);
      const aiResponseText = result.response.candidates?.[0]
        ?.content?.parts?.[0]?.text ?? "";

      const insightDoc = {
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        summaryText: aiResponseText,
        type: "weekly",
      };

      await firestore.collection("userProfiles").doc(userId)
        .collection("insights").add(insightDoc);

      return {message: "Insight generated successfully!"};
    } catch (error) {
      console.error("Error in generateWeeklyInsight:", error);
      throw new functions.https.HttpsError(
        "internal", "Failed to generate weekly insight.");
    }
  },
);

export const suggestNutritionGoals = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "You must be logged in.");
    }

    const {
      primaryGoal, biologicalSex, weightKg, heightCm, activityLevel,
    } = request.data;
    if (
      !primaryGoal || !biologicalSex || !weightKg || !heightCm || !activityLevel
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Missing required profile data.");
    }

    const prompt = `
      You are an expert nutritionist. Calculate daily nutrition goals
      (calories, protein, carbs, fat) based on user data.
      IMPORTANT: Respond with ONLY a valid JSON object.
      User Data:
      - Goal: ${primaryGoal}, Sex: ${biologicalSex}, Weight: ${weightKg} kg,
      - Height: ${heightCm} cm, Activity: ${activityLevel}
    `;

    try {
      const result = await generativeModel.generateContent(prompt);
      let jsonString = result.response.candidates?.[0]
        ?.content?.parts?.[0]?.text ?? "{}";

      if (jsonString.startsWith("```json")) {
        jsonString = jsonString.substring(7, jsonString.length - 3);
      }

      const goals = JSON.parse(jsonString);
      return goals;
    } catch (error) {
      console.error("Error in suggestNutritionGoals:", error);
      throw new functions.https.HttpsError(
        "internal", "Failed to generate nutrition goals.");
    }
  },
);

// FIX: Restored the missing generateMealInsight function
export const generateMealInsight = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "You must be logged in.");
    }
    const {primaryGoal, meal} = request.data;
    if (!primaryGoal || !meal) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Missing required profile goal or meal data.");
    }

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
      `;

    try {
      const result = await generativeModel.generateContent(prompt);
      const insightText = result.response.candidates?.[0]
        ?.content?.parts?.[0]?.text ?? "";

      return {insightText: insightText.trim()};
    } catch (error) {
      console.error("Error calling AI model for meal insight:", error);
      throw new functions.https.HttpsError(
        "internal", "Failed to generate AI meal insight.");
    }
  },
);

export const aiAssistant = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "You must be logged in.");
    }
    const userId = request.auth.uid;
    const {userPrompt} = request.data;
    if (!userPrompt) {
      throw new functions.https.HttpsError(
        "invalid-argument", "A prompt is required.");
    }

    const createProgramTool: Tool = {
      functionDeclarations: [
        {
          name: "createNewWorkoutProgram",
          description: "Creates a new, empty workout program for the user.",
          parameters: {
            type: "OBJECT",
            properties: {
              name: {type: "STRING"},
              days: {type: "NUMBER"},
            },
            required: ["name", "days"],
          } as FunctionDeclarationSchema,
        },
      ],
    };

    try {
      const chat = generativeModel.startChat({tools: [createProgramTool]});
      const result1 = await chat.sendMessage(userPrompt);
      const call = result1.response.candidates?.[0]
        ?.content?.parts[0]?.functionCall;

      if (call) {
        const {name, days} = call.args as { name: string; days: number };
        const defaultDays: WorkoutDay[] = Array.from(
          {length: days},
          (_, i) => ({dayName: `Day ${i + 1}`, exercises: []}),
        );
        const newProgram = {name, days: defaultDays};
        await firestore.collection("userProfiles").doc(userId)
          .collection("workoutPrograms").add(newProgram);
        const result2 = await chat.sendMessage([
          {
            functionResponse: {
              name: "createNewWorkoutProgram",
              response: {name, success: true},
            },
          },
        ]);
        const responseText = result2.response.candidates?.[0]
          ?.content?.parts[0]?.text ?? "";
        return {responseText: responseText.trim()};
      } else {
        const responseText = result1.response.candidates?.[0]
          ?.content?.parts[0]?.text ?? "";
        return {responseText: responseText.trim()};
      }
    } catch (error) {
      console.error("Error in aiAssistant:", error);
      throw new functions.https.HttpsError(
        "internal", "The AI assistant encountered an error.");
    }
  },
);

export const processWorkoutUserInput = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "You must be logged in.");
    }
    const {userInput, currentWorkout, chatHistory} = request.data;
    if (!userInput || !currentWorkout) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Missing required workout data.");
    }

    const workoutJson = JSON.stringify(currentWorkout);
    const historyJson = JSON.stringify(chatHistory);

    const prompt = `
      You are an expert fitness coach and a precise data entry assistant.
      Your task is to analyze a user's text command and update their
      current workout session data accordingly.

      RULES:
      - Infer the exercise based on the user's command and chat history.
      - If a correction is provided, modify the LAST logged set.
      - You MUST return a single, valid JSON object.
      - If the command is conversational, set "updated_workout_json" to null.
      - If the user is 'done' with an exercise, update its 'status' field
        in the JSON to 'complete'.

      INPUT:
      - current_workout_json: ${workoutJson}
      - user_input: "${userInput}"
      - chat_history: ${historyJson}

      OUTPUT FORMAT:
      {
        "updated_workout_json": The complete, modified workout JSON object,
        "response_message": "A short, encouraging confirmation message."
      }
    `;

    try {
      const result = await generativeModel.generateContent(prompt);
      const responseText = result.response.candidates?.[0]
        ?.content?.parts?.[0]?.text?.trim() ?? "{}";

      const startIndex = responseText.indexOf("{");
      const endIndex = responseText.lastIndexOf("}");
      if (startIndex === -1 || endIndex === -1) {
        return {response_message: "Sorry, I had trouble with that."};
      }
      const jsonString = responseText.substring(startIndex, endIndex + 1);
      return JSON.parse(jsonString);
    } catch (error) {
      console.error("Error in processWorkoutUserInput:", error);
      throw new functions.https.HttpsError(
        "internal", "Failed to process workout input.");
    }
  },
);

export const getMealFromText = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated", "You must be logged in.");
  }
  const {inputText} = request.data;
  if (!inputText) {
    throw new functions.https.HttpsError(
      "invalid-argument", "Input text is required.");
  }

  const prompt = `
      You are an expert nutrition parser. Analyze the user's text and
      extract detailed meal information. Return a single, valid JSON object.
      JSON STRUCTURE:
      {
        "mealName": "...", "totalProtein": 0.0, "totalCarbs": 0.0,
        "totalFat": 0.0, "totalCalories": 0.0, "foods": [
          {"name": "...", "protein": 0.0, "carbs": 0.0, "fat": 0.0,
          "calories": 0.0}
        ]
      }
      Meal Description: ${inputText}
    `;

  try {
    const result = await generativeModel.generateContent(prompt);
    let jsonString = result.response.candidates?.[0]
      ?.content?.parts?.[0]?.text ?? "{}";
    if (jsonString.startsWith("```json")) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    }
    return JSON.parse(jsonString);
  } catch (error) {
    console.error("Error in getMealFromText:", error);
    throw new functions.https.HttpsError(
      "internal", "Failed to parse meal data.");
  }
});

// Define interfaces for our data to avoid using 'any'
interface SetData {
  weight: number;
  reps: number;
}

interface ExerciseData {
  name: string;
  sets: SetData[];
}

export const getWorkoutInsights = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated", "You must be logged in.");
  }
  const {completedWorkout, lastSessionData, userProfile} = request.data;
  if (!completedWorkout || !lastSessionData || !userProfile) {
    throw new functions.https.HttpsError(
      "invalid-argument", "Missing required data for insights.");
  }

  const unitSuffix = userProfile.unitSystem === "metric" ? "kg" : "lbs";

  const currentSummary = completedWorkout.exercises
    .map((e: ExerciseData) =>
      `${e.name}: ${e.sets.map((s: SetData) =>
        `${s.weight}${unitSuffix} x ${s.reps}reps`).join(", ")}`)
    .join("\n");

  // FIX: Broke the long line into multiple lines for readability
  // and to satisfy the linter.
  const entries = Object.entries(lastSessionData) as
    [string, ExerciseData | null][];
  const previousSummary = entries.map(([key, value]) => {
    if (!value) return `${key}: No data`;
    return `${value.name}: ${value.sets.map((s: SetData) =>
      `${s.weight}${unitSuffix} x ${s.reps}reps`).join(", ")}`;
  }).join("\n");

  const prompt = `
      You are an expert fitness coach. The user's preferred unit is
      ${unitSuffix}. Analyze their workout and provide a concise summary.
      STRUCTURE:
      Overall Session Insights: [Your summary]
      ---
      Performance Notes: [Bulleted list of observations]
      ---
      Recommendations for Next Time: [Bulleted list of tips]

      CURRENT WORKOUT:
      ${currentSummary}

      PREVIOUS WORKOUT:
      ${previousSummary}
    `;

  try {
    const result = await generativeModel.generateContent(prompt);
    return {
      insightText: result.response.candidates?.[0]
        ?.content?.parts?.[0]?.text ?? "",
    };
  } catch (error) {
    console.error("Error in getWorkoutInsights:", error);
    throw new functions.https.HttpsError(
      "internal", "Failed to generate workout insights.");
  }
});
