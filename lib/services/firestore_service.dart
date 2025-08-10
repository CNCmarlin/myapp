// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/workout_data.dart';
import '../models/user_profile.dart';
import '../models/meal_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

   Future<WorkoutProgram?> getWorkoutProgramById(String userId, String programId) async {
    try {
      final programDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('workoutPrograms')
          .doc(programId)
          .get();
      if (programDoc.exists) {
        return WorkoutProgram.fromMap(programDoc.data()!)..id = programDoc.id;
      }
      return null;
    } catch (e) {
      print('Error getting workout program by ID: $e');
      return null;
    }
  }

  // In lib/services/firestore_service.dart

// REPLACE the existing getWorkoutProgram method with this one.
Future<Workout?> getWorkoutProgram(String userId, String programId, int dayIndex) async {
  try {
    // THIS IS THE FIX: We now use the userId to build the correct path
    // to the user's private subcollection.
    final programDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('workoutPrograms')
        .doc(programId)
        .get();

    if (!programDoc.exists) {
      print('Workout program document not found for this user.');
      return null;
    }

    final workoutProgram = WorkoutProgram.fromMap(programDoc.data()!);

    if (dayIndex < 0 || dayIndex >= workoutProgram.days.length) {
      print('Invalid day index.');
      return null;
    }

    final workoutDay = workoutProgram.days[dayIndex];
    
    // The rest of the method's logic for creating a temporary Workout object remains the same.
    return Workout(
      id: '${programDoc.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      date: DateTime.now(),
      name: workoutDay.dayName,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      duration: "N/A",
      caloriesBurned: 0.0,
      exercises: workoutDay.exercises,
    );
  } catch (e) {
    print('Error getting workout program: $e');
    return null;
  }
}

  Future<void> logSet(String userId, String workoutId, String exerciseName, ExerciseSet newSet) async {
    // This method is intentionally left blank as we save the entire workout at the end.
    // This prevents numerous unnecessary writes to the database for each set.
    // Logic can be added here in the future if set-by-set real-time updates are desired.
  }

  Future<List<WorkoutProgram>> getAllWorkoutPrograms(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workoutPrograms')
          .get();
      return snapshot.docs.map((doc) {
        return WorkoutProgram.fromMap(doc.data())..id = doc.id;
      }).toList();
    } catch (e) {
      print('Error getting all workout programs: $e');
      return [];
    }
  }
  
  Future<String> createNewWorkoutProgram(String userId, String programName) async {
  try {
    final List<WorkoutDay> defaultDays = List.generate(7, (index) {
      return WorkoutDay(
        dayName: 'Day ${index + 1}',
        exercises: [],
      );
    });
    
    final newProgram = WorkoutProgram(id: '', name: programName, days: defaultDays);

    // Get the DocumentReference from the 'add' call
    final docRef = await _db.collection('users').doc(userId).collection('workoutPrograms').add(newProgram.toMap());
    
    // Return the unique ID of the newly created document
    return docRef.id;

  } catch (e) {
    throw Exception('Error creating new workout program: $e');
  }
}
  
  Future<void> updateWorkoutProgram(String userId, WorkoutProgram updatedProgram) async {
    try {
      final programRef = _db
          .collection('users')
          .doc(userId)
          .collection('workoutPrograms')
          .doc(updatedProgram.id);
      await programRef.set(updatedProgram.toMap());
    } catch (e) {
      throw Exception('Error updating workout program: $e');
    }
  }
  
  Future<void> updateWorkoutDay(String userId, String programId, int dayIndex, List<Exercise> newExercises) async {
    try {
      final programRef = _db
          .collection('users')
          .doc(userId)
          .collection('workoutPrograms')
          .doc(programId);

      final programDoc = await programRef.get();

      if (!programDoc.exists) {
        throw Exception('Workout program document not found.');
      }

      final workoutProgram = WorkoutProgram.fromMap(programDoc.data()!);

      if (dayIndex < 0 || dayIndex >= workoutProgram.days.length) {
        throw Exception('Invalid day index.');
      }

      workoutProgram.days[dayIndex].exercises = newExercises;

      await programRef.set(workoutProgram.toMap());
    } catch (e) {
      throw Exception('Error updating workout day: $e');
    }
  }

  // In lib/services/firestore_service.dart

Future<void> updateWorkoutDayName(String userId, String programId, int dayIndex, String newDayName) async {
  try {
    final programRef = _db
        .collection('users')
        .doc(userId)
        .collection('workoutPrograms')
        .doc(programId);

    // 1. Get the full program document from Firestore.
    final programDoc = await programRef.get();
    if (!programDoc.exists) {
      throw Exception("Program not found");
    }

    // 2. Convert the data to our Dart model.
    final program = WorkoutProgram.fromMap(programDoc.data()!);

    // 3. Modify the day name in the local Dart object.
    if (dayIndex >= 0 && dayIndex < program.days.length) {
      program.days[dayIndex].dayName = newDayName;
    } else {
      throw Exception("Invalid day index");
    }

    // 4. Write the entire updated program object back to Firestore.
    await programRef.set(program.toMap());

  } catch (e) {
    print('Error updating day name: $e');
    throw Exception('Error updating day name: $e');
  }
}

  // Add these two methods inside your FirestoreService class
  
  Future<void> updateProgramName(String userId, String programId, String newName) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('workoutPrograms')
          .doc(programId)
          .update({'name': newName});
    } catch (e) {
      throw Exception('Error updating program name: $e');
    }
  }

Future<void> deleteWorkoutProgram(String userId, String programId) async {
  try {
    await _db
        .collection('users')
        .doc(userId)
        .collection('workoutPrograms')
        .doc(programId)
        .delete();
  } catch (e) {
    throw Exception('Error deleting workout program: $e');
  }
}

// Fetches an in-progress workout for a specific date, if one exists.
Future<Workout?> getInProgressWorkout(String userId, DateTime date) async {
  final dateId = DateFormat('yyyy-MM-dd').format(date);
  final doc = await _db
      .collection('users')
      .doc(userId)
      .collection('inProgressWorkouts')
      .doc(dateId)
      .get();
  if (doc.exists) {
    return Workout.fromMap(doc.data()!);
  }
  return null;
}

// Saves the current workout state to the in-progress document.
Future<void> saveInProgressWorkout(String userId, Workout workout) async {
  final dateId = DateFormat('yyyy-MM-dd').format(workout.date);
  await _db
      .collection('users')
      .doc(userId)
      .collection('inProgressWorkouts')
      .doc(dateId)
      .set(workout.toMap());
}

// Deletes the in-progress document, typically after a workout is completed.
Future<void> deleteInProgressWorkout(String userId, DateTime date) async {
  final dateId = DateFormat('yyyy-MM-dd').format(date);
  await _db.collection('users').doc(userId).collection('inProgressWorkouts').doc(dateId).delete();
}

  Future<Exercise?> getPreviousExerciseLog(String userId, String exerciseName) async {
    try {
      final workoutLogsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workoutLogs')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      for (final workoutDoc in workoutLogsSnapshot.docs) {
        final workoutData = Workout.fromMap(workoutDoc.data());
        try {
          return workoutData.exercises.firstWhere(
              (exercise) => exercise.name.toLowerCase() == exerciseName.toLowerCase());
        } catch (e) {
          // Exercise not found in this log, continue to the next
        }
      }
      return null;
    } catch (e) {
      print('Error getting previous exercise log: $e');
      return null;
    }
  }
  
  Future<void> saveWorkoutLog(String userId, Workout workout) async {
    try {
      final workoutRef = _db
          .collection('users')
          .doc(userId)
          .collection('workoutLogs')
          .doc(workout.id);
      await workoutRef.set(workout.toMap());
    } catch (e) {
      throw Exception('Error saving workout log: $e');
    }
  }

  Future<Workout?> getWorkoutLogByDate(String userId, DateTime date) async {
     try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workoutLogs')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Workout.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting workout log by date: $e');
      return null;
    }
  }
  
// Add this complete method inside your FirestoreService class

Future<void> createNewUserProfile(User user, UserProfile profile) async {
  try {
    // We use the user's unique ID from authentication as the document ID
    // and the UserProfile object's map as the data.
    await _db.collection('users').doc(user.uid).set(profile.toMap());
  } catch (e) {
    print('Error creating new user profile: $e');
    throw Exception('Error creating new user profile: $e');
  }
}

  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    try {
      await _db.collection('users').doc(userId).set(profile.toMap());
    } catch (e) {
      throw Exception('Error saving user profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  Future<NutritionLog?> getNutritionLog(String userId, DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('nutritionLogs')
          .doc(formattedDate)
          .get();
      if (doc.exists) {
        return NutritionLog.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting nutrition log: $e');
      return null;
    }
  }

  Future<void> saveNutritionLog(String userId, NutritionLog log) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(log.date);
      await _db
          .collection('users')
          .doc(userId)
          .collection('nutritionLogs')
          .doc(formattedDate)
          .set(log.toMap());
    } catch (e) {
      throw Exception('Error saving nutrition log: $e');
    }
  }
}