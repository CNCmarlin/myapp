// import * as functions from "firebase-functions";
//import {
  //WorkoutProgram,
  //Meal,
  //Exercise as ExerciseData, // Alias Exercise to match existing code
 // ExerciseSet as SetData,
  // Insight, // Alias ExerciseSet to match existing code
//} from "./models";
// import * as admin from "firebase-admin";
// import {
//   VertexAI,
//   HarmCategory,
//   HarmBlockThreshold,
//   Tool,
//   FunctionDeclarationSchema,
//   FunctionDeclarationSchemaType, // ADD THIS IMPORT
// } from "@google-cloud/vertexai";

// admin.initializeApp();
// const firestore = admin.firestore();

// const projectId = process.env.GCLOUD_PROJECT;
// if (!projectId) {
//   throw new Error("GCLOUD_PROJECT environment variable not set.");
// }

// const vertexAI = new VertexAI({project: projectId, location: "us-central1"});

// const generativeModel = vertexAI.getGenerativeModel({
//   model: "gemini-2.5-flash",
//   safetySettings: [
//     {
//       category: HarmCategory.HARM_CATEGORY_HARASSMENT,
//       threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
//     },
//     {
//       category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
//       threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
//     },
//   ],
// });

// functions/src/index.ts

// functions/src/index.ts

// export const aiAssistantRouter = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }

//     const {prompt, history, userProfile} = request.data;
//     if (!prompt || !userProfile) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "A prompt and userProfile are required.");
//     }

//     const transformedHistory = (history || []).map((message: any) => ({
//       role: message.isUser ? "user" : "model",
//       parts: [{text: message.text}],
//     })).reverse();

//     const tools: Tool = {
//       functionDeclarations: [
//         {
//           name: "generate_workout_program",
//           description: "Generates a detailed, personalized workout program.",
//           parameters: {
//             type: FunctionDeclarationSchemaType.OBJECT,
//             properties: {
//               prompt: {
//                 type: FunctionDeclarationSchemaType.STRING,
//                 description: "The user's specific request, e.g., " +
//                 "'a 4-day upper/lower split'",
//               },
//               equipmentInfo: {
//                 type: FunctionDeclarationSchemaType.STRING,
//                 description: "The user's available equipment, e.g., " +
//                 "'Public Gym', 'Home Gym', 'Bodyweight Only'",
//               },
//             },
//             required: ["prompt", "equipmentInfo"],
//           },
//         },
//         {
//           name: "get_fitness_advice",
//           description: "Answers user questions about general fitness, " +
//             "exercise techniques, workout tips, and training principles.",
//           parameters: {
//             type: FunctionDeclarationSchemaType.OBJECT,
//             properties: {
//               question: {
//                 type: FunctionDeclarationSchemaType.STRING,
//                 description: "The user's specific fitness-related question.",
//               },
//             },
//             required: ["question"],
//           },
//         },
//         {
//           name: "get_nutrition_advice",
//           description: "Answers user questions about nutrition, food, diets, " +
//             "healthy habits, and macronutrients.",
//           parameters: {
//             type: FunctionDeclarationSchemaType.OBJECT,
//             properties: {
//               question: {
//                 type: FunctionDeclarationSchemaType.STRING,
//                 description: "The user's specific nutrition-related question.",
//               },
//             },
//             required: ["question"],
//           },
//         },
//       ],
//     };

//     const model = vertexAI.getGenerativeModel({
//       model: "gemini-1.5-flash",
//       tools: [tools],
//     });

//     const chat = model.startChat({history: transformedHistory});
//     const result = await chat.sendMessage(prompt);
//     const candidate = result.response.candidates?.[0];
//     const call = candidate?.content?.parts[0]?.functionCall;

//     if (call) {
//       let specializedPrompt = "";
//       const question = (call.args as { question: string }).question || prompt;

//       switch (call.name) {
//       case "generate_workout_program": {
//         const program = await exports.generateAiWorkoutProgram.run(
//           {...request, data: {...call.args, userProfile}},
//           {auth: request.auth}
//         );
//         return {type: "program", data: program};
//       }
//       case "get_fitness_advice":
//         specializedPrompt = `
//             You are an expert personal trainer and fitness coach.
//             A user has the following question: "${question}".
//             Provide a clear, helpful, and encouraging answer.
//             Use markdown for formatting if appropriate.
//           `;
//         break;
//       case "get_nutrition_advice":
//         specializedPrompt = `
//             You are an expert nutritionist and dietary coach.
//             A user has the following question: "${question}".
//             Provide a clear, helpful, and encouraging answer.
//             Use markdown for formatting if appropriate.
//           `;
//         break;
//       default:
//         return {type: "text", data: "I'm not sure how to handle that request."};
//       }

//       const specializedResult = await generativeModel
//         .generateContent(specializedPrompt);
//       const responseText = specializedResult.response.candidates?.[0]
//         ?.content?.parts[0]?.text ?? "I'm not sure how to respond to that.";
//       return {type: "text", data: responseText.trim()};
//     } else {
//       const responseText = candidate?.content?.parts[0]?.text ??
//         "I'm not sure how to respond to that.";
//       return {type: "text", data: responseText.trim()};
//     }
//   },
// );

// export const generateSummaryInsight = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const userId = request.auth.uid;
//     const {isMonthly} = request.data;
//     const daysToAnalyze = isMonthly ? 30 : 7;

//     const dateToCompare = new Date();
//     dateToCompare.setDate(dateToCompare.getDate() - daysToAnalyze);

//     try {
//       const userProfile = (await firestore.collection("userProfiles")
//         .doc(userId).get()).data();
//       if (!userProfile) {
//         throw new functions.https.HttpsError("not-found", "User not found.");
//       }

//       const workoutLogsPromise = firestore.collection("userProfiles")
//         .doc(userId)
//         .collection("workoutLogs")
//         .where("date", ">=", dateToCompare)
//         .get();
//       const nutritionLogsPromise = firestore
//         .collection("userProfiles")
//         .doc(userId)
//         .collection("nutritionLogs")
//         .where("date", ">=", dateToCompare)
//         .get();

//       const [workoutSnap, nutritionSnap] = await Promise.all([
//         workoutLogsPromise,
//         nutritionLogsPromise,
//       ]);

//       const workoutData = workoutSnap.docs.map((doc) => doc.data());
//       const nutritionData = nutritionSnap.docs.map((doc) => doc.data());

//       if (workoutData.length === 0 && nutritionData.length === 0) {
//         throw new functions.https.HttpsError(
//           "not-found", `No data to analyze for ${daysToAnalyze} days.`);
//       }

//       const prompt = `
//           You are an expert fitness and nutrition coach. Analyze the following 
//           data for the last ${daysToAnalyze} days for a user whose goal is
//           "${userProfile.primaryGoal}".
//           **Analyze for the following patterns:**
//           1.  **Performance Trend:** Identify the single most improved lift.
//           2.  **Milestone:** Celebrate a consistency achievement.
//           3.  **Nutrition Correlation:** Find a link between nutrition and
//               performance.
//           4.  **Weekly Summary:** Provide a standard summary for the last 7
//               days.

//            **CRITICAL:** Respond with ONLY the user-facing text in markdown 
//             format.
//             Do NOT include the markdown for headers like "###". Just provide the
//             formatted text content.
//             The structure for each object MUST be:
          
//             "A short, engaging title for the section (BOLD).",
//             "A 1-2 paragraph explanation in markdown.",
//             "'Perforemance': 'Milestones': 'Nutrition': etc.",
//             "related data" eg: "exercise": "Bench Press", "improvement": "10%"

//              **CRITICAL:** Respond with ONLY the user-facing text in markdown format.
//              Do NOT include the markdown for headers like "###". Just provide the
//               formatted text content. Start with a bolded title on the first line.
//               It should look as though a human formatted it and not include any
//               {, *, chars.
          

//           **Data:**
//           - Workouts: ${JSON.stringify(workoutData).substring(0, 3000)}
//           - Nutrition: ${JSON.stringify(nutritionData).substring(0, 3000)}
//         `;

//       const result = await generativeModel.generateContent(prompt);
//       const summaryText = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "Could not generate summary.";

//       const insightDoc = {
//         title: isMonthly ? "Monthly Summary" : "Weekly Summary",
//         summaryText: summaryText,
//         insightType: "WEEKLY_SUMMARY",
//         isRead: false,
//         generatedAt: admin.firestore.FieldValue.serverTimestamp(),
//       };

//       await firestore.collection("userProfiles").doc(userId)
//         .collection("insights").add(insightDoc);

//       return {message: "Insight generated successfully!"};
//     } catch (error) {
//       console.error("Error in generateSummaryInsight:", error);
//       if (error instanceof functions.https.HttpsError) {
//         throw error;
//       }
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate summary insight.");
//     }
//   },
// );

// // functions/src/index.ts

// // REPLACE THIS FUNCTION
// export const getWorkoutSummary = functions.https.onCall(async (request) => {
//   if (!request.auth) {
//     throw new functions.https.HttpsError(
//       "unauthenticated", "You must be logged in.");
//   }
//   const {completedWorkout, lastSessionData, userProfile} = request.data;
//   if (!completedWorkout || !lastSessionData || !userProfile) {
//     throw new functions.https.HttpsError(
//       "invalid-argument", "Missing required data for summary.");
//   }

//   // UPDATED PROMPT
//   const prompt = `
//     You are a fitness coach analyzing a user's just-completed workout
//     compared to their last session. Your tone is concise and encouraging.

//     **User Goal:** ${userProfile.primaryGoal}
//     **Unit System:** ${userProfile.unitSystem}

//     **Your Task:**
//     1.  Compare the 'completedWorkout' to the 'lastSessionData'.
//     2.  **Crucially, pay attention to any user 'notes' on exercises.** A note
//         like "felt a pinch" or "form felt off" is very important.
//     3.  Highlight 1-2 key improvements (increased weight or reps).
//     4.  If performance decreased, gently mention it and correlate with any
//         notes if possible (e.g., "It looks like bench press was a bit
//         lighter today; I see you noted some shoulder pain.").
//     5.  If there's a clear trend, provide one brief, actionable tip for the
//         next session.
//     6.  Keep the entire response under 75 words.

//      **CRITICAL:** Respond with ONLY the user-facing text in markdown format.
//           Do NOT include the markdown for headers like "###". Just provide the
//           formatted text content. Start with a bolded title on the first line.


//     **Completed Workout Data:** ${JSON.stringify(completedWorkout)}
//     **Last Session Data:** ${JSON.stringify(lastSessionData)}
//   `;

//   try {
//     const result = await generativeModel.generateContent(prompt);
//     const summaryText = result.response.candidates?.[0]
//       ?.content?.parts?.[0]?.text ?? "Could not generate summary.";
//     return {summaryText: summaryText};
//   } catch (error) {
//     console.error("Error in getWorkoutSummary:", error);
//     throw new functions.https.HttpsError(
//       "internal", "Failed to generate workout summary.");
//   }
// });

// export const generateWorkoutInsight = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const userId = request.auth.uid;
//     const sevenDaysAgo = new Date();
//     sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

//     try {
//       const userProfile = (await firestore.collection("userProfiles")
//         .doc(userId).get()).data();
//       if (!userProfile) {
//         throw new functions.https.HttpsError("not-found", "User not found.");
//       }

//       const workoutSnap = await firestore.collection("userProfiles").doc(userId)
//         .collection("workoutLogs").where("date", ">=", sevenDaysAgo).get();

//       const workoutData = workoutSnap.docs.map((doc) => doc.data());

//       if (workoutData.length === 0) {
//         throw new functions.https.HttpsError(
//           "not-found", "No workout data to analyze for the last 7 days.");
//       }

//       const prompt = `
//         You are an expert personal trainer providing a weekly performance
//         review. Your tone is analytical, motivating, and forward-looking.

//         **User Profile & Goals:**
//         - Primary Goal: ${userProfile.primaryGoal}
//         - Fitness Level: ${userProfile.fitnessProficiency}

//         **Your Task:**
//         1.  Analyze all workouts from the past 7 days.
//         2.  **Pay close attention to user notes.** Look for recurring themes
//             like "felt tired," "form was great," or mentions of pain.
//         3.  Identify the "Workout of the Week" (the session with the most
//             personal records or volume improvements) and praise the user for it.
//         4.  Find one area for improvement, using their notes for context. For
//             example, if they often note fatigue on leg day, suggest a 
//             pre-workout carb snack. If they note pain, advise them 
//             to be cautious.
//         5.  Conclude with an encouraging statement for the week ahead.
//         6.  Keep the entire response under 150 words.

//         **CRITICAL:** Respond with ONLY the user-facing text in markdown format.
//           Do NOT include the markdown for headers like "###". Just provide the
//           formatted text content. Start with a bolded title on the first line.


//         **Workout Data:**
//         ${JSON.stringify(workoutData).substring(0, 4000)}
//       `;

//       const result = await generativeModel.generateContent(prompt);
//       const summaryText = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "Could not generate workout insight.";

//       const insightDoc = {
//         title: "Your Weekly Trainer Review",
//         summaryText: summaryText,
//         insightType: "PERFORMANCE_TREND",
//         isRead: false,
//         generatedAt: admin.firestore.FieldValue.serverTimestamp(),
//       };

//       await firestore.collection("userProfiles").doc(userId)
//         .collection("insights").add(insightDoc);

//       return {message: "Workout insight generated successfully!"};
//     } catch (error) {
//       console.error("Error in generateWorkoutInsight:", error);
//       if (error instanceof functions.https.HttpsError) {
//         throw error;
//       }
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate workout insight.");
//     }
//   },
// );

// export const generateNutritionInsight = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const userId = request.auth.uid;
//     const sevenDaysAgo = new Date();
//     sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

//     try {
//       const userProfile = (await firestore.collection("userProfiles")
//         .doc(userId).get()).data();
//       if (!userProfile) {
//         throw new functions.https.HttpsError("not-found", "User not found.");
//       }

//       const nutritionSnap = await firestore
//         .collection("userProfiles")
//         .doc(userId)
//         .collection("nutritionLogs")
//         .where("date", ">=", sevenDaysAgo)
//         .get();

//       const nutritionData = nutritionSnap.docs.map((doc) => doc.data());

//       if (nutritionData.length === 0) {
//         throw new functions.https.HttpsError(
//           "not-found", "No nutrition data to analyze for the last 7 days.");
//       }

//       // ENHANCED PROMPT
//       const prompt = `
//         You are an expert nutrition coach with a light, honest, and encouraging
//         tone. Analyze the user's nutrition data for the last 7 days against
//         their stated goals.

//         **User Profile & Goals:**
//         - Primary Goal: ${userProfile.primaryGoal}
//         - Target Calories: ${userProfile.targetCalories}
//         - Target Protein: ${userProfile.targetProtein}g
//         - Target Carbs: ${userProfile.targetCarbs}g
//         - Target Fat: ${userProfile.targetFat}g

//         **Your Task:**
//         1.  Analyze the user's logged meals, **paying special attention to any
//             notes,** like "felt bloated" or "this was a great snack."
//         2.  If the user is consistently eating high-calorie or processed foods
//             that conflict with their goals, gently point this out.
//         3.  Identify a pattern from their notes. For example, if they often
//             feel tired after a certain meal, or feel great after another.
//         4.  If the user is consistantly over by 30-50g of a target macro gently
//             suggest ways to improve this metric by replacing certain foods with
//             ones to achive thier goals.
//         5.  Provide one piece of positive reinforcement based on a good choice
//             or positive note they made.
//         6.  Offer a single, actionable suggestion for a healthier alternative
//             or habit. For example, "I noticed a few high-sugar snacks. Have you
//             considered swapping one for *instert better food option here*? 
//             It's higher in protein and will keep you full longer." 
//         7.  Keep the entire response positive but honest and under
//             150-200 words.

//         **CRITICAL:** Respond with ONLY the user-facing text in markdown format.
//           Do NOT include the markdown for headers like "###". Just provide the
//           formatted text content. Start with a bolded title on the first line.


//         **Nutrition Data:**
//         ${JSON.stringify(nutritionData).substring(0, 4000)}
//       `;

//       const result = await generativeModel.generateContent(prompt);
//       const summaryText = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "Could not generate nutrition insight.";

//       const insightDoc = {
//         title: "Your Weekly Nutrition Review",
//         summaryText: summaryText,
//         insightType: "NUTRITION_CORRELATION",
//         isRead: false,
//         generatedAt: admin.firestore.FieldValue.serverTimestamp(),
//       };

//       await firestore.collection("userProfiles").doc(userId)
//         .collection("insights").add(insightDoc);

//       return {message: "Nutrition insight generated successfully!"};
//     } catch (error) {
//       console.error("Error in generateNutritionInsight:", error);
//       if (error instanceof functions.https.HttpsError) {
//         throw error;
//       }
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate nutrition insight.");
//     }
//   },
// );

// export const suggestNutritionGoals = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const {
//       primaryGoal, biologicalSex, weight, height, activityLevel,
//       prefersLowCarb, weeklyWeightLossGoal, exerciseDaysPerWeek,
//       fitnessProficiency,
//     } = request.data;
//     if (
//       !primaryGoal || !biologicalSex || !weight || !height || !activityLevel
//     ) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "Missing required profile data.");
//     }
//     const weightKg = weight.unit === "lbs" ?
//       weight.value * 0.453592 : weight.value;
//     const heightCm = height.value; // Assuming height is always passed in cm now

//     const prompt = `
//       You are an expert nutritionist following a strict calculation protocol.

//       **USER DATA:**
//       - Primary Goal: ${primaryGoal}
//       - Biological Sex: ${biologicalSex}
//       - Weight: ${weightKg.toFixed(2)} kg
//       - Height: ${heightCm.toFixed(2)} cm
//       - Age: 25 (assumed)
//       - Fitness Proficiency: ${fitnessProficiency || "Beginner"}
//       - Daily Activity (Non-Exercise): "${activityLevel}"
//       - Exercise Days/Week: ${exerciseDaysPerWeek}
//       - Preference: ${prefersLowCarb ? "Low-Carb" : "Standard"}
//       - Weight Loss Goal: ${weeklyWeightLossGoal} lbs/week (if applicable)

//       **PROTOCOL:**
//       1.  **Calculate BMR (Mifflin-St Jeor):**
//           - Male: (10 * weight in kg) + (6.25 * height in cm) - (5 * age) + 5
//           - Female: (10 * wgt in kg) + (6.25 * hgt in cm) - (5 * age) - 161
//       2.  **Calculate TDEE:**
//           - TDEE = BMR * Activity Multiplier (Sedentary: 1.2, Lightly:
//             1.375, Mod: 1.55, Very: 1.725).
//       3.  **Add Exercise Bonus:**
//           - Daily Bonus = (Exercise Days * Calories per Session) / 7.
//           - (Beginner: 300, Intermediate: 400, Advanced: 500 kcal).
//           - Final TDEE = TDEE + Daily Bonus.
//       4.  **Adjust for Goal:**
//           - Lose Weight: Subtract deficit for goal (1lb = 3500kcal/wk).
//           - Gain Muscle: Add 350 kcal surplus.
//           - Maintain: No change.
//       5.  **Calculate Macros:**
//           - Protein (g) = Weight (kg) * 1.8.
//           - Fat (g) = (Final Calories * 0.25) / 9.
//           - Carbs (g) = (Final Calories - (Protein*4 + Fat*9)) / 4.
//           - If Low-Carb: Carbs = (Final Calories * 0.20) / 4, recalculate
//             Fat with remaining calories.
//       6.  **Final Check:** The sum of (Protein*4 + Carbs*4 + Fat*9) MUST
//           be within 20 calories of your final calorie target. Adjust carbs
//           slightly to match if needed.

//       **OUTPUT:** Respond with ONLY a valid JSON object. All values must be
//       rounded to a whole number.
//       {
//         "targetCalories": number, "targetProtein": number,
//         "targetCarbs": number, "targetFat": number
//       }
//     `;

//     try {
//       const result = await generativeModel.generateContent(prompt);
//       let jsonString = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "{}";
//       if (jsonString.startsWith("```json")) {
//         jsonString = jsonString.substring(7, jsonString.length - 3);
//       }
//       return JSON.parse(jsonString);
//     } catch (error) {
//       console.error("Error in suggestNutritionGoals:", error);
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate nutrition goals.");
//     }
//   },
// );

// export const generateMealInsight = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const {primaryGoal, meal} = request.data;
//     if (!primaryGoal || !meal) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "Missing required profile goal or meal data.");
//     }
//     const prompt = `
//         You are a positive fitness coach. A user's goal is "${primaryGoal}".
//         Their meal: Calories: ${meal.calories}, Protein: ${meal.protein}g,
//         Carbs: ${meal.carbs}g, Fat: ${meal.fat}g.
//         Write a single, encouraging sentence (under 20 words)
//         positively framing how this meal impacts their goal.
//       `;
//     try {
//       const result = await generativeModel.generateContent(prompt);
//       const insightText = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "";
//       return {insightText: insightText.trim()};
//     } catch (error) {
//       console.error("Error calling AI model for meal insight:", error);
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate AI meal insight.");
//     }
//   },
// );

// export const aiAssistant = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const userId = request.auth.uid;
//     const {userPrompt} = request.data;
//     if (!userPrompt) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "A prompt is required.");
//     }

//     const createProgramTool: Tool = {
//       functionDeclarations: [
//         {
//           name: "createNewWorkoutProgram",
//           description: "Creates a new, empty workout program for the user.",
//           parameters: {
//             type: FunctionDeclarationSchemaType.OBJECT,
//             properties: {
//               name: {type: FunctionDeclarationSchemaType.STRING},
//               days: {type: FunctionDeclarationSchemaType.NUMBER},
//             },
//             required: ["name", "days"],
//           } as FunctionDeclarationSchema,
//         },
//       ],
//     };

//     try {
//       const chat = generativeModel.startChat({tools: [createProgramTool]});
//       const result1 = await chat.sendMessage(userPrompt);
//       const call = result1.response.candidates?.[0]
//         ?.content?.parts[0]?.functionCall;

//       if (call) {
//         const {name, days} = call.args as { name: string; days: number };
//         const defaultDays = Array.from(
//           {length: days},
//           (_, i) => ({dayName: `Day ${i + 1}`, exercises: []}),
//         );
//         const newProgram = {name, days: defaultDays};
//         await firestore.collection("userProfiles").doc(userId)
//           .collection("workoutPrograms").add(newProgram);
//         const result2 = await chat.sendMessage([
//           {
//             functionResponse: {
//               name: "createNewWorkoutProgram",
//               response: {name, success: true},
//             },
//           },
//         ]);
//         const responseText = result2.response.candidates?.[0]
//           ?.content?.parts[0]?.text ?? "";
//         return {responseText: responseText.trim()};
//       } else {
//         const responseText = result1.response.candidates?.[0]
//           ?.content?.parts[0]?.text ?? "";
//         return {responseText: responseText.trim()};
//       }
//     } catch (error) {
//       console.error("Error in aiAssistant:", error);
//       throw new functions.https.HttpsError(
//         "internal", "The AI assistant encountered an error.");
//     }
//   },
// );

// export const calculateMacrosFromCalories = functions.https.onCall(
//   async (request) => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const {
//       targetCalories,
//       userProfile,
//     } = request.data;
//     if (!targetCalories || !userProfile) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "Missing required calorie or profile data.");
//     }

//     const weightKg = userProfile.weight.unit === "lbs" ?
//       userProfile.weight.value * 0.453592 : userProfile.weight.value;

//     const prompt = `
//       You are an expert nutritionist following a strict calculation protocol.

//       **USER DATA:**
//       - Target Calories: ${targetCalories}
//       - Weight: ${weightKg.toFixed(2)} kg
//       - Primary Goal: ${userProfile.primaryGoal}
//       - Dietary Preference: ${userProfile.prefersLowCarb ?
//     "Low-Carb" : "Standard"}

//       **PROTOCOL:**
//       1.  **Calculate Protein:**
//           - Protein (g) = Weight (kg) * 1.8.
//       2.  **Calculate Fat:**
//           - Fat (g) = (Target Calories * 0.25) / 9.
//       3.  **Calculate Carbs:**
//           - Carbs (g) = (Target Calories - (Protein*4 + Fat*9)) / 4.
//       4.  **Low-Carb Adjustment:**
//           - If preference is "Low-Carb", set Carbs to (Target Calories *
//             0.20) / 4 and recalculate Fat with the remaining calories.
//       5.  **Final Check:** The sum of (Protein*4 + Carbs*4 + Fat*9) MUST
//           be within 10 calories of the Target Calories. Adjust carbs
//           slightly if needed to match.

//       **IMPORTANT:** Respond with ONLY a valid JSON object. All values must
//       be rounded to a whole number.
//       {
//         "targetProtein": number,
//         "targetCarbs": number,
//         "targetFat": number
//       }
//     `;

//     try {
//       const result = await generativeModel.generateContent(prompt);
//       let jsonString = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "{}";
//       if (jsonString.startsWith("```json")) {
//         jsonString = jsonString.substring(7, jsonString.length - 3);
//       }
//       return JSON.parse(jsonString);
//     } catch (error) {
//       console.error("Error in calculateMacrosFromCalories:", error);
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate macros.");
//     }
//   },
// );

// // functions/src/index.ts

// export const getMealFromText = functions.https.onCall(
//   async (request): Promise<Meal> => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const {inputText} = request.data;
//     if (!inputText) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "Input text is required.");
//     }

//     // UPDATED PROMPT
//     const prompt = `
//       You are an expert nutrition parser. Your task is to analyze the user's
//       text and extract detailed meal information into a single, valid JSON
//       object.

//       **CRITICAL RULE:**
//       If the user describes a composite food item (e.g., "a ham and cheese
//       sandwich", "a bowl of oatmeal with berries"), you MUST identify the
//       primary item and return it as a SINGLE entry in the "foods" array.
//       Do NOT break it down into its constituent ingredients in the array.
//       Instead, list the key ingredients within the "name" field for clarity.

//       **EXAMPLES:**
//       - User Input: "I had a turkey and swiss sandwich on rye"
//       - Correct Output: { "mealName": "Lunch", "foods": [{ "name":
//         "Sandwich - Turkey, Swiss, Rye", ... }] }
//       - User Input: "a bowl of cheerios with milk and a banana"
//       - Correct Output: { "mealName": "Breakfast", "foods": [{ "name":
//         "Cheerios with Milk and Banana", ... }] }
//       - User Input: "2 eggs, 3 strips of bacon, and a coffee"
//       - Correct Output: { "mealName": "Breakfast", "foods": [
//         { "name": "Eggs", ... },
//         { "name": "Bacon", ... },
//         { "name": "Coffee", ... }
//       ] }


//       **JSON STRUCTURE:**
//       {
//         "mealName": "...", "protein": 0.0, "carbs": 0.0, "fat": 0.0,
//         "calories": 0.0, "foods": [
//           {"name": "...", "protein": 0.0, "carbs": 0.0, "fat": 0.0,
//           "calories": 0.0}
//         ]
//       }

//       **Meal Description to Parse:** "${inputText}"
//     `;

//     try {
//       const result = await generativeModel.generateContent(prompt);
//       let jsonString = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "{}";
//       if (jsonString.startsWith("```json")) {
//         jsonString = jsonString.substring(7, jsonString.length - 3);
//       }
//       const mealData = JSON.parse(jsonString) as Meal;
//       return mealData;
//     } catch (error) {
//       console.error("Error in getMealFromText:", error);
//       throw new functions.https.HttpsError(
//         "internal", "Failed to parse meal data.");
//     }
//   });

// export const getWorkoutInsights = functions.https.onCall(async (request) => {
//   if (!request.auth) {
//     throw new functions.https.HttpsError(
//       "unauthenticated", "You must be logged in.");
//   }
//   const {completedWorkout, lastSessionData, userProfile} = request.data;
//   if (!completedWorkout || !lastSessionData || !userProfile) {
//     throw new functions.https.HttpsError(
//       "invalid-argument", "Missing required data for insights.");
//   }

//   const unitSuffix = userProfile.unitSystem === "metric" ? "kg" : "lbs";

//   const currentSummary = completedWorkout.exercises
//     .map((e: ExerciseData) => // Now uses the imported aliased type
//       `${e.name}: ${e.sets.map((s: SetData) =>
//         `${s.weight}${unitSuffix} x ${s.reps}reps`).join(", ")}`)
//     .join("\n");

//   const entries = Object.entries(lastSessionData) as
//       [string, ExerciseData | null][]; // Now uses the imported aliased type
//   const previousSummary = entries.map(([key, value]) => {
//     if (!value) return `${key}: No data`;
//     return `${value.name}: ${value.sets.map((s: SetData) =>
//       `${s.weight}${unitSuffix} x ${s.reps}reps`).join(", ")}`;
//   }).join("\n");

//   const prompt = `
//         You are a fitness coach. The user's unit is ${unitSuffix}. Analyze
//         their workout and provide a concise summary.

//         *IMPORTANT* do not inlude any ** use nothing. a dot, or a - instead
//         STRUCTURE:
//         Overall Session Insights: [Your summary]
//         ---
//         Performance Notes: [Bulleted list]
//         ---
//         Recommendations for Next Time: [Bulleted list]
//         CURRENT WORKOUT: ${currentSummary}
//         PREVIOUS WORKOUT: ${previousSummary}
//       `;

//   try {
//     const result = await generativeModel.generateContent(prompt);
//     return {
//       insightText: result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "",
//     };
//   } catch (error) {
//     console.error("Error in getWorkoutInsights:", error);
//     throw new functions.https.HttpsError(
//       "internal", "Failed to generate workout insights.");
//   }
// });

// export const generateAiWorkoutProgram = functions.https.onCall(
//   async (request): Promise<WorkoutProgram> => {
//     if (!request.auth) {
//       throw new functions.https.HttpsError(
//         "unauthenticated", "You must be logged in.");
//     }
//     const {prompt, equipmentInfo, userProfile} = request.data;
//     if (!prompt || !equipmentInfo || !userProfile) {
//       throw new functions.https.HttpsError(
//         "invalid-argument", "Missing required data.");
//     }

//     const finalPrompt = `
//       You are an expert fitness coach creating a personalized workout program.

//       **USER PROFILE:**
//       - Goal: ${userProfile.primaryGoal}
//       - Fitness Level: ${userProfile.fitnessProficiency || "Beginner"}
//       - Exercise Days Per Week: ${userProfile.exerciseDaysPerWeek}

//       **USER'S REQUEST:** "${prompt}"
//       **EQUIPMENT AVAILABILITY:** "${equipmentInfo}"

//       **TASK:**
//       1. Analyze all available data to create a suitable workout program.
//       2. Tailor the exercise selection, volume (sets/reps), and
//          complexity directly to the user's stated **Fitness Level**.
//          - **Beginner:** Focus on compound movements, simple progressions.
//          - **Intermediate:** Introduce more variety and isolation work.
//          - **Advanced:** Assume high work capacity; can include advanced
//            techniques like supersets or dropsets if appropriate.
//       3. Create a concise, motivating name for the program.
//       4. For each day, provide a functional name (e.g., "Full Body A").
//       5. For each exercise, provide a standard target (e.g., "3x 8-12 reps").

//       **IMPORTANT:** Respond with ONLY a valid JSON object.
//       The JSON structure must be:
//       {
//         "id": "", "name": "AI Program Name", "days": [
//           {"dayName": "Day 1: Upper Body", "exercises": [
//             {"name": "Bench Press", "programTarget": "4x 8-10 reps",
//              "status": "Incomplete", "sets": []}
//           ]}
//         ]
//       }
//     `;

//     try {
//       const result = await generativeModel.generateContent(finalPrompt);
//       let jsonString = result.response.candidates?.[0]
//         ?.content?.parts?.[0]?.text ?? "{}";
//       if (jsonString.startsWith("```json")) {
//         jsonString = jsonString.substring(7, jsonString.length - 3);
//       }

//       // Cast the parsed object to our strict WorkoutProgram interface
//       const programData = JSON.parse(jsonString) as WorkoutProgram;
//       if (!programData.name || !programData.days) {
//         throw new Error("AI response was not a valid program structure.");
//       }
//       return programData;
//     } catch (error) {
//       console.error("Error in generateAiWorkoutProgram:", error);
//       throw new functions.https.HttpsError(
//         "internal", "Failed to generate AI workout program.");
//     }
//   },
// );
