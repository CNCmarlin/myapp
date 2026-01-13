import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';
import '../models/workout_data.dart';
import '../models/meal_data.dart';

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

  // Workout History CRUD
  Future<List<Workout>> getWorkoutHistory() async {
    return await isar.workouts.where().sortByDateDesc().findAll();
  }

  Future<void> saveWorkout(Workout workout) async {
    await isar.writeTxn(() async {
      await isar.workouts.put(workout);
    });
  }

  // Nutrition Log CRUD
  Future<NutritionLog?> getNutritionLogByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await isar.nutritionLogs
        .filter()
        .dateGreaterThan(startOfDay.subtract(const Duration(seconds: 1)))
        .and()
        .dateLessThan(endOfDay)
        .findFirst();
  }

  Future<void> saveNutritionLog(NutritionLog log) async {
    await isar.writeTxn(() async {
      await isar.nutritionLogs.put(log);
    });
  }

  Future<NutritionLog?> getNutritionLogByDate(DateTime date) async {
    final dateString = "${date.year}-${date.month}-${date.day}";
    // Standard Isar query using the date index
    return await isar.nutritionLogs.filter().idEqualTo(dateString).findFirst();
  }

  Future<void> saveNutritionLog(NutritionLog log) async {
    await isar.writeTxn(() async {
      await isar.nutritionLogs.put(log);
    });
  }

  // 🛡️ SHIELD: Targeted Program Updates
  Future<void> updateProgramName(String programId, String newName) async {
    await isar.writeTxn(() async {
      final program =
          await isar.workoutPrograms.filter().idEqualTo(programId).findFirst();
      if (program != null) {
        program.name = newName;
        await isar.workoutPrograms.put(program);
      }
    });
  }
}
