// functions/src/models.ts

import * as admin from "firebase-admin";

/**
 * Represents a single set of an exercise, matching the Flutter model.
 */
export interface ExerciseSet {
  id: string;
  weight: number;
  reps: number;
  notes?: string;
}

/**
 * Represents a single exercise, matching the Flutter model.
 */
export interface Exercise {
  name: string;
  status: string;
  programTarget: string;
  sets: ExerciseSet[];
  notes?: string;
}

/**
 * Represents a single day within a workout program, matching the Flutter model.
 */
export interface WorkoutDay {
  dayName: string;
  exercises: Exercise[];
}

/**
 * Represents a full workout program, matching the Flutter model.
 */
export interface WorkoutProgram {
  id: string;
  name: string;
  days: WorkoutDay[];
}

/**
 * Represents a single food item, matching the Flutter model.
 */
export interface FoodItem {
  name: string;
  protein: number;
  carbs: number;
  fat: number;
  calories: number;
}

/**
 * Represents a full meal, matching the Flutter model.
 */
export interface Meal {
  mealName: string;
  foods: FoodItem[];
  protein: number;
  carbs: number;
  fat: number;
  calories: number;
  aiInsight?: string;
}

export interface Insight {
  id?: string;
  title: string;
  summaryText: string;
  // CORRECTED: Line is now under 80 characters
  insightType: "PERFORMANCE_TREND" | "NUTRITION_CORRELATION" | "MILESTONE" |
    "WEEKLY_SUMMARY";
  generatedAt: admin.firestore.Timestamp;
  // CORRECTED: Replaced 'any' with a more specific type for relatedData
  relatedData?: {[key: string]: string | number | boolean};
  isRead: boolean;
}
