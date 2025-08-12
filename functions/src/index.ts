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
  // FIX: Using the user-requested gemini-2.5-flash model.
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

interface SetData {
  weight: number;
  reps: number;
}

interface ExerciseData {
  name: string;
  sets: SetData[];
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
      primaryGoal, biologicalSex, weight, height, activityLevel,
      prefersLowCarb, weeklyWeightLossGoal, exerciseDaysPerWeek,
    } = request.data;
    if (
      !primaryGoal || !biologicalSex || !weight || !height || !activityLevel
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument", "Missing required profile data.");
    }
    const weightKg = weight.unit === "lbs" ?
      weight.value * 0.453592 : weight.value;
    const heightCm = height.unit === "cm" ?
      height.value : height.value;
    const prompt = `
      You are an expert nutritionist. Your task is to calculate a highly
      personalized daily nutrition plan based on detailed user data.
      **USER DATA:**
      - Primary Goal: ${primaryGoal}
      - Biological Sex: ${biologicalSex}
      - Weight: ${weightKg.toFixed(2)} kg, Height: ${heightCm.toFixed(2)} cm
      - Daily Activity Level (Non-Exercise): "${activityLevel}"
      - Planned Exercise Days Per Week: ${exerciseDaysPerWeek}
      - Dietary Preference: ${prefersLowCarb ? "Prefers Low-Carb" : "Standard"}
      - Weekly Weight Loss Goal: ${weeklyWeightLossGoal} lbs (if applicable)
      **IMPORTANT:** Respond with ONLY a valid JSON object.
      {
        "targetCalories": number, "targetProtein": number,
        "targetCarbs": number, "targetFat": number
      }
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
      console.error("Error in suggestNutritionGoals:", error);
      throw new functions.https.HttpsError(
        "internal", "Failed to generate nutrition goals.");
    }
  },
);

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
        You are a positive fitness coach. A user's goal is "${primaryGoal}".
        Their meal: Calories: ${meal.calories}, Protein: ${meal.protein}g,
        Carbs: ${meal.carbs}g, Fat: ${meal.fat}g.
        Write a single, encouraging sentence (under 20 words)
        positively framing how this meal impacts their goal.
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
              name: {type: "STRING"}, days: {type: "NUMBER"},
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

    const prompt = `
      You are a fitness coach and data entry assistant. Analyze the user's
      command and update their workout JSON.
      RULES: Infer exercise from context. Modify the LAST set for
      corrections. Return ONLY a valid JSON object. If conversational,
      set "updated_workout_json" to null. If user is 'done', set
      exercise 'status' to 'complete'.
      INPUT:
      - current_workout_json: ${JSON.stringify(currentWorkout)}
      - user_input: "${userInput}"
      - chat_history: ${JSON.stringify(chatHistory)}
      OUTPUT FORMAT:
      {
        "updated_workout_json": The modified workout JSON or null,
        "response_message": "A short confirmation message."
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
      You are a nutrition parser. Analyze the text and extract meal info
      into a single, valid JSON object.
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

  const entries = Object.entries(lastSessionData) as
    [string, ExerciseData | null][];
  const previousSummary = entries.map(([key, value]) => {
    if (!value) return `${key}: No data`;
    return `${value.name}: ${value.sets.map((s: SetData) =>
      `${s.weight}${unitSuffix} x ${s.reps}reps`).join(", ")}`;
  }).join("\n");

  const prompt = `
      You are a fitness coach. The user's unit is ${unitSuffix}. Analyze
      their workout and provide a concise summary.
      STRUCTURE:
      Overall Session Insights: [Your summary]
      ---
      Performance Notes: [Bulleted list]
      ---
      Recommendations for Next Time: [Bulleted list]
      CURRENT WORKOUT: ${currentSummary}
      PREVIOUS WORKOUT: ${previousSummary}
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

// THIS IS THE NEW FUNCTION THAT WAS MISSING
export const generateAiWorkoutProgram = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated", "You must be logged in.");
    }
    const {prompt, equipmentInfo} = request.data;
    if (!prompt || !equipmentInfo) {
      throw new functions.https.HttpsError(
        "invalid-argument", "A prompt and equipment info are required.");
    }

    const finalPrompt = `
      You are an expert fitness coach creating a personalized workout program.
      **USER'S REQUEST:** "${prompt}"
      **EQUIPMENT AVAILABILITY:** "${equipmentInfo}"
      **TASK:**
      1. Analyze the user's request for days, split, and goals.
      2. Create a complete workout program based on the request and equipment.
      3. For each day, provide a name (e.g., "Chest & Triceps Push Day").
      4. For each exercise, provide a target (e.g., "3x 8-12 reps").
      **IMPORTANT:** Respond with ONLY a valid JSON object.
      The JSON structure must be:
      {
        "id": "", "name": "AI Generated Program Name", "days": [
          {"dayName": "Day 1: Chest & Triceps", "exercises": [
              {"name": "Bench Press", "programTarget": "4x 8-10 reps",
               "status": "Incomplete", "sets": []}
          ]}
        ]
      }
    `;

    try {
      const result = await generativeModel.generateContent(finalPrompt);
      const jsonString = result.response.candidates?.[0]
        ?.content?.parts?.[0]?.text ?? "{}";

      const programData = JSON.parse(jsonString);
      if (!programData.name || !programData.days) {
        throw new Error("AI response was not a valid program structure.");
      }

      return programData;
    } catch (error) {
      console.error("Error in generateAiWorkoutProgram:", error);
      throw new functions.https.HttpsError(
        "internal", "Failed to generate AI workout program.");
    }
  },
);
