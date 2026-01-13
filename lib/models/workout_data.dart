// lib/models/workout_data.dart

import 'package:isar/isar.dart';

part 'workout_data.g.dart'; // Change: Added for code generation

@collection
class WorkoutProgram {
  Id isarId = Isar.autoIncrement; // Change: Added required integer Id for Isar collection

  @Index(unique: true, replace: true) // Change: Added index for string ID to maintain legacy lookups
  String id;
  String name;
  List<WorkoutDay> days;

  WorkoutProgram({
    required this.id,
    required this.name,
    required this.days,
  });
  
  WorkoutProgram copyWith({
    String? id,
    String? name,
    List<WorkoutDay>? days,
  }) {
    return WorkoutProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
    );
  }

  factory WorkoutProgram.fromMap(Map<String, dynamic> map) {
    return WorkoutProgram(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Program',
      days: (map['days'] as List<dynamic>?)
              ?.map((d) => WorkoutDay.fromMap(d))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'days': days.map((d) => d.toMap()).toList(),
    };
  }
}

@embedded 
class WorkoutDay {
  String? dayName;
  List<Exercise>? exercises;

  // Fix: Added braces to make parameters optional and avoid "missing default value" errors
  WorkoutDay({this.dayName, this.exercises});


  factory WorkoutDay.fromMap(Map<String, dynamic> map) {
    return WorkoutDay(
      dayName: map['dayName'] ?? 'Unnamed Day',
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayName': dayName,
      // Fix: Added null-aware operator to handle nullable exercises list
      'exercises': exercises?.map((e) => e.toMap()).toList() ?? [],
    };
  }
}

@collection // Change: Mark as standalone table for history
class Workout {
  Id isarId = Isar.autoIncrement; // Change: Required integer ID

  @Index(unique: true, replace: true)
  String id;
  String name; 
  DateTime date;
  DateTime startTime;
  DateTime endTime;
  String duration;
  double caloriesBurned;
  List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name, // <-- FIELD ADDED
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.caloriesBurned,
    required this.exercises,
  });

  // Helper function to handle both DateTime and String
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is DateTime) { // Change: Handle local DateTime directly
      return dateValue;
    } else if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    // Fallback for safety, though it shouldn't be needed
    return DateTime.now();
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      name: map['name'] ?? 'Unnamed Workout', // <-- FIELD ADDED
      date: Workout._parseDate(map['date']),
      startTime: Workout._parseDate(map['startTime']),
      endTime: Workout._parseDate(map['endTime']),
      duration: map['duration'] ?? 'N/A',
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name, // <-- FIELD ADDED
      'date': date,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}

@embedded 
class Exercise {
  String? name;
  String? status;
  String? programTarget;
  List<ExerciseSet>? sets;
  String? notes;

  Exercise({
    this.name,
    this.status,
    this.programTarget,
    this.sets,
    this.notes,
  }); // Change: Removed 'required' and braces to align constructor with nullable fields

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      status: map['status'] ?? 'Incomplete',
      programTarget: map['programTarget'] ?? '',
      sets: (map['sets'] as List<dynamic>?)
              ?.map((s) => ExerciseSet.fromMap(s))
              .toList() ??
          [],
      notes: map['notes'], // UPDATED FACTORY
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'programTarget': programTarget,
      // Fix: Added null-aware operator to sets map to handle the new nullable model structure
      'sets': sets?.map((s) => s.toMap()).toList() ?? [], 
      'notes': notes,
    };
  }
}


@embedded // Change: Added required annotation for nested schema generation
class ExerciseSet {
  String? id;
  double? weight;
  int? reps;
  String? notes;

  ExerciseSet({
    this.id,
    this.weight,
    this.reps,
    this.notes,
  }); // Change: Constructor updated for null-safe hydration

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'reps': reps,
      'notes': notes,
    };
  }
  
}

// Add these extensions to the bottom of lib/models/workout_data.dart

extension WorkoutCopyWith on Workout {
  Workout copyWith({
    String? id,
    String? name,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? duration,
    double? caloriesBurned,
    List<Exercise>? exercises,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      exercises: exercises ?? this.exercises,
    );
  }
}

extension ExerciseCopyWith on Exercise {
  Exercise copyWith({
    String? name,
    String? status,
    String? programTarget,
    List<ExerciseSet>? sets,
    String? notes,
  }) {
    return Exercise(
      name: name ?? this.name,
      status: status ?? this.status,
      programTarget: programTarget ?? this.programTarget,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}
