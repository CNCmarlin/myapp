import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection // LOCAL FIRST: Annotation required for Isar to recognize this class as a table
class UserProfile {
  Id id = Isar.autoIncrement;
  String? activityLevel;
  String? primaryGoal;
  String? activeProgramId;
  String? unitSystem;
  String? biologicalSex;
  double? bodyFatPercentage;
  WeightData? weight;
  HeightData? height;
  MeasurementData? measurements;
  WeightData? goalWeight;
  bool onboardingCompleted;
  double? targetCalories;
  double? targetProtein;
  double? targetCarbs;
  double? targetFat;
  bool prefersLowCarb;
  double weeklyWeightLossGoal;
  int exerciseDaysPerWeek;
  String? fitnessProficiency;
  DateTime? birthDate;
  DateTime? lastSynced;
  bool isDirty = false;

  int? get calculatedAge {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    if (today.month < birthDate!.month || (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  UserProfile({
    this.activityLevel,
    this.primaryGoal,
    this.activeProgramId,
    this.biologicalSex,
    this.unitSystem = 'imperial',
    this.bodyFatPercentage,
    this.weight,
    this.height,
    this.measurements,
    this.onboardingCompleted = false,
    this.targetCalories = 0.0,
    this.targetProtein = 0.0,
    this.targetCarbs = 0.0,
    this.targetFat = 0.0,
    this.prefersLowCarb = false,
    this.weeklyWeightLossGoal = 1.0,
    this.exerciseDaysPerWeek = 3,
    this.fitnessProficiency = 'Beginner',
    this.birthDate,
    this.goalWeight,
    this.lastSynced,
    this.isDirty = false,
  });

  // SHIELD: Legacy Getters to support existing code expecting Maps
  @ignore // DETERMINISM: Tells Isar not to attempt persisting this unsupported type
  Map<String, dynamic>? get weightMap => weight?.toMap();
  
  @ignore // DETERMINISM: Tells Isar not to attempt persisting this unsupported type
  Map<String, dynamic>? get heightMap => height?.toMap();
  
  @ignore // DETERMINISM: Tells Isar not to attempt persisting this unsupported type
  Map<String, dynamic>? get measurementsMap => measurements?.toMap();
  
  @ignore // DETERMINISM: Tells Isar not to attempt persisting this unsupported type
  Map<String, dynamic>? get goalWeightMap => goalWeight?.toMap();

  Map<String, dynamic> toMap() {
    return {
      'activityLevel': activityLevel,
      'primaryGoal': primaryGoal,
      'biologicalSex': biologicalSex,
      'bodyFatPercentage': bodyFatPercentage,
      'weight': weight?.toMap(),
      'activeProgramId': activeProgramId,
      'unitSystem': unitSystem,
      'height': height?.toMap(),
      'measurements': measurements?.toMap(),
      'onboardingCompleted': onboardingCompleted,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'prefersLowCarb': prefersLowCarb,
      'weeklyWeightLossGoal': weeklyWeightLossGoal,
      'exerciseDaysPerWeek': exerciseDaysPerWeek,
      'fitnessProficiency': fitnessProficiency,
      'birthDate': birthDate?.toIso8601String(),
      'goalWeight': goalWeight?.toMap(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      activityLevel: map['activityLevel'],
      primaryGoal: map['primaryGoal'],
      activeProgramId: map['activeProgramId'],
      unitSystem: map['unitSystem'] ?? 'imperial',
      biologicalSex: map['biologicalSex'],
      bodyFatPercentage: (map['bodyFatPercentage'] as num?)?.toDouble(),
      weight: map['weight'] != null ? WeightData.fromMap(map['weight']) : null,
      height: map['height'] != null ? HeightData.fromMap(map['height']) : null,
      measurements: map['measurements'] != null
          ? MeasurementData.fromMap(map['measurements'])
          : null,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      targetCalories: (map['targetCalories'] as num?)?.toDouble() ?? 0.0,
      targetProtein: (map['targetProtein'] as num?)?.toDouble() ?? 0.0,
      targetCarbs: (map['targetCarbs'] as num?)?.toDouble() ?? 0.0,
      targetFat: (map['targetFat'] as num?)?.toDouble() ?? 0.0,
      prefersLowCarb: map['prefersLowCarb'] ?? false,
      weeklyWeightLossGoal:
          (map['weeklyWeightLossGoal'] as num?)?.toDouble() ?? 1.0,
      exerciseDaysPerWeek: (map['exerciseDaysPerWeek'] as num?)?.toInt() ?? 3,
      fitnessProficiency: map['fitnessProficiency'] ?? 'Beginner',
      birthDate: map['birthDate'] != null ? DateTime.tryParse(map['birthDate']) : null,
      goalWeight: map['goalWeight'] != null
          ? WeightData.fromMap(map['goalWeight'])
          : null,
    );
  }

  UserProfile copyWith({
    String? activityLevel,
    String? primaryGoal,
    String? activeProgramId,
    String? biologicalSex,
    String? unitSystem,
    double? bodyFatPercentage,
    WeightData? weight,
    HeightData? height,
    MeasurementData? measurements,
    bool? onboardingCompleted,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    bool? prefersLowCarb,
    double? weeklyWeightLossGoal,
    int? exerciseDaysPerWeek,
    String? fitnessProficiency,
    DateTime? birthDate,
    WeightData? goalWeight,
    DateTime? lastSynced,
    bool? isDirty,
  }) {
    return UserProfile(
      activityLevel: activityLevel ?? this.activityLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      activeProgramId: activeProgramId ?? this.activeProgramId,
      unitSystem: unitSystem ?? this.unitSystem,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      measurements: measurements ?? this.measurements,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      prefersLowCarb: prefersLowCarb ?? this.prefersLowCarb,
      weeklyWeightLossGoal: weeklyWeightLossGoal ?? this.weeklyWeightLossGoal,
      exerciseDaysPerWeek: exerciseDaysPerWeek ?? this.exerciseDaysPerWeek,
      fitnessProficiency: fitnessProficiency ?? this.fitnessProficiency,
      birthDate: birthDate ?? this.birthDate,
      goalWeight: goalWeight ?? this.goalWeight,
      lastSynced: lastSynced ?? this.lastSynced,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

@embedded
class WeightData {
  double? value;
  String? unit;
  WeightData({this.value, this.unit});

  dynamic operator [](String key) {
    if (key == 'value') return value;
    if (key == 'unit') return unit;
    return null;
  }

  static WeightData? fromAny(dynamic input) {
    if (input is WeightData) return input;
    if (input is Map<String, dynamic>) return WeightData.fromMap(input);
    return null;
  }

  Map<String, dynamic> toMap() => {'value': value, 'unit': unit};
  factory WeightData.fromMap(Map<String, dynamic> map) =>
      WeightData(value: (map['value'] as num?)?.toDouble(), unit: map['unit']);
}

@embedded
class HeightData {
  double? value;
  String? unit;
  HeightData({this.value, this.unit});

  dynamic operator [](String key) {
    if (key == 'value') return value;
    if (key == 'unit') return unit;
    return null;
  }

  static HeightData? fromAny(dynamic input) {
    if (input is HeightData) return input;
    if (input is Map<String, dynamic>) return HeightData.fromMap(input);
    return null;
  }

  Map<String, dynamic> toMap() => {'value': value, 'unit': unit};
  factory HeightData.fromMap(Map<String, dynamic> map) =>
      HeightData(value: (map['value'] as num?)?.toDouble(), unit: map['unit']);
}

@embedded
class MeasurementData {
  double? waist;
  double? neck;
  String? unit;
  MeasurementData({this.waist, this.neck, this.unit});

  dynamic operator [](String key) {
    if (key == 'waist') return waist;
    if (key == 'neck') return neck;
    if (key == 'unit') return unit;
    return null;
  }

  static MeasurementData? fromAny(dynamic input) {
    if (input is MeasurementData) return input;
    if (input is Map<String, dynamic>) return MeasurementData.fromMap(input);
    return null;
  }

  Map<String, dynamic> toMap() => {'waist': waist, 'neck': neck, 'unit': unit};
  factory MeasurementData.fromMap(Map<String, dynamic> map) => MeasurementData(
        waist: (map['waist'] as num?)?.toDouble(),
        neck: (map['neck'] as num?)?.toDouble(),
        unit: map['unit'],
      );
}
