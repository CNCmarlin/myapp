import 'package:isar/isar.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/insight_data.dart';
import '../models/user_profile.dart';
import '../models/workout_data.dart';
import '../models/meal_data.dart';
import '../models/chat_message.dart';

class LocalStorageService {
  late Isar isar;

  // Initialize the singleton instance of Isar
  Future<void> init() async {
    // Cross-Platform FS: Deterministically find the documents directory
    final dir = await getApplicationDocumentsDirectory();

    // Open Isar with all hardened schemas
    isar = await Isar.open(
      [
        UserProfileSchema,
        WorkoutProgramSchema,
        WorkoutSchema,
        NutritionLogSchema,
        ChatMessageSchema, // Fix: Added missing schema for persistent chat
      ],
      directory: dir.path,
    );
  }

  // User Profile CRUD
  Future<UserProfile?> getUserProfile() async {
    return await isar.userProfiles.where().findFirst();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await isar.writeTxn(() async {
      await isar.userProfiles.put(profile);
    });
  }

  // Workout Program CRUD (Used by WorkoutProvider)
  Future<List<WorkoutProgram>> getAllWorkoutPrograms() async {
    return await isar.workoutPrograms.where().findAll();
  }

  Future<void> saveWorkoutProgram(WorkoutProgram program) async {
    await isar.writeTxn(() async {
      await isar.workoutPrograms.put(program);
    });
  }

  Future<void> updateProgramName(String programId, String newName) async {
    // Lookup by the indexed string ID to bridge legacy Firestore relationships
    final program =
        await isar.workoutPrograms.filter().idEqualTo(programId).findFirst();
    if (program != null) {
      await isar.writeTxn(() async {
        program.name = newName;
        await isar.workoutPrograms.put(program);
      });
    }
  }

  Future<Workout?> getInProgressWorkout(DateTime date) async {
    return await getWorkoutByDate(date);
  }

  Future<void> saveInProgressWorkout(Workout workout) async {
    await saveWorkout(workout);
  }

  Future<void> saveWorkoutLog(Workout workout) async {
    await saveWorkout(workout);
  }

  Future<void> deleteInProgressWorkout(DateTime date) async {
    final workout = await getWorkoutByDate(date);
    if (workout != null) {
      await isar.writeTxn(() async {
        await isar.workouts.delete(workout.isarId); 
      });
    }
  }

  Future<Exercise?> getPreviousExerciseLog(String exerciseName) async {
    final workouts = await isar.workouts.where().sortByDateDesc().findAll();
    for (var workout in workouts) {
      final match = workout.exercises.firstWhere(
        (e) => (e.name ?? '') == exerciseName && (e.sets?.isNotEmpty ?? false),
        orElse: () => Exercise(name: '', sets: []),
      );
      
      if (match.name?.isNotEmpty ?? false) return match;
    }
    return null;
  }

  Future<Workout?> getWorkoutByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await isar.workouts
        .filter()
        .dateGreaterThan(startOfDay.subtract(const Duration(seconds: 1)))
        .and()
        .dateLessThan(endOfDay)
        .findFirst();
  }

  Future<void> deleteWorkoutProgram(String programId) async {
    await isar.writeTxn(() async {
      await isar.workoutPrograms.filter().idEqualTo(programId).deleteFirst();
    });
  }

  Future<List<ChatMessage>> getChatHistory() async {
    // Retrieval: Fetches last 20 messages sorted by time
    return await isar.chatMessages.where().sortByTimestampDesc().limit(20).findAll();
  }

  Future<void> saveChatMessage(ChatMessage message) async {
    await isar.writeTxn(() async {
      await isar.chatMessages.put(message);
    });
  }

  // 🛡️ SHIELD: Local Context Retrieval (Surgically removed duplicates)
  Future<Workout?> getLatestWorkout() async {
    // Logic: Pulls the most recent workout from local history
    return await isar.workouts.where().sortByDateDesc().findFirst();
  }

  Future<List<NutritionLog>> getRecentNutrition(int days) async {
    final threshold = DateTime.now().subtract(Duration(days: days));
    // Retrieval: Pulls logs for context within a specific window
    return await isar.nutritionLogs.filter().dateGreaterThan(threshold).findAll();
  }

  // Fix: Unified the date-based nutrition lookup (Removed duplicates from lines 75-101)
  Future<NutritionLog?> getNutritionLogByDate(DateTime date) async {
    final dateString = "${date.year}-${date.month}-${date.day}";
    return await isar.nutritionLogs.filter().idEqualTo(dateString).findFirst();
  }

  Future<void> saveNutritionLog(NutritionLog log) async {
    await isar.writeTxn(() async {
      await isar.nutritionLogs.put(log);
    });
  }

  // Workout History CRUD
  Future<List<Workout>> getWorkoutHistory() async {
    return await isar.workouts.where().sortByDateDesc().findAll();
  }

  Future<void> saveWorkout(Workout workout) async {
    await isar.writeTxn(() async {
      await isar.workouts.put(workout);
    });
  }

  Future<String> createBackupCopy() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupPath = "${dir.path}/sync_snapshot.isar";
    final backupFile = File(backupPath);
    
    // Clean up previous snapshots before creating a new one
    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    // Surgical Intervention: Use Isar's internal copy method to bypass active file locks
    await isar.copyToFile(backupPath);
    return backupPath;
  }
  
  Future<List<Workout>> getWorkoutsInRange(DateTime start, DateTime end) async {
    return await isar.workouts.filter()
        .dateBetween(start, end)
        .findAll();
  }

  Future<List<NutritionLog>> getNutritionInRange(DateTime start, DateTime end) async {
    return await isar.nutritionLogs.filter()
        .dateBetween(start, end)
        .findAll();
  }

  Future<void> saveInsight(Insight insight) async {
    await isar.writeTxn(() async {
      await isar.insights.put(insight);
    });
  }

  Stream<List<Insight>> watchInsights() {
    return isar.insights.where()
        .sortByGeneratedAtDesc()
        .watch(fireImmediately: true);
  }
}
