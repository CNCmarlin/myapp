
class UserProfile {
  String? activityLevel;
  String? primaryGoal;
  String? activeProgramId;
  String? unitSystem;
  String? biologicalSex;
  double? bodyFatPercentage;
  Map<String, dynamic>? weight;
  Map<String, dynamic>? height;
  Map<String, dynamic>? measurements;
  bool onboardingCompleted;
  double? targetCalories;
  double? targetProtein;
  double? targetCarbs;
  double? targetFat;
  bool prefersLowCarb;
  double weeklyWeightLossGoal;
  int exerciseDaysPerWeek;
  String? fitnessProficiency;
  int? age;
  Map<String, dynamic>? goalWeight; // NEW FIELD

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
    this.age,
    this.goalWeight, // NEW FIELD
  });

  Map<String, dynamic> toMap() {
    return {
      'activityLevel': activityLevel,
      'primaryGoal': primaryGoal,
      'biologicalSex': biologicalSex,
      'bodyFatPercentage': bodyFatPercentage,
      'weight': weight,
      'activeProgramId': activeProgramId,
      'unitSystem': unitSystem,
      'height': height,
      'measurements': measurements,
      'onboardingCompleted': onboardingCompleted,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'prefersLowCarb': prefersLowCarb,
      'weeklyWeightLossGoal': weeklyWeightLossGoal,
      'exerciseDaysPerWeek': exerciseDaysPerWeek,
      'fitnessProficiency': fitnessProficiency,
      'age': age,
      'goalWeight': goalWeight, // NEW FIELD
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
      weight: map['weight'],
      height: map['height'],
      measurements: map['measurements'],
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      targetCalories: (map['targetCalories'] as num?)?.toDouble() ?? 0.0,
      targetProtein: (map['targetProtein'] as num?)?.toDouble() ?? 0.0,
      targetCarbs: (map['targetCarbs'] as num?)?.toDouble() ?? 0.0,
      targetFat: (map['targetFat'] as num?)?.toDouble() ?? 0.0,
      prefersLowCarb: map['prefersLowCarb'] ?? false,
      weeklyWeightLossGoal: (map['weeklyWeightLossGoal'] as num?)?.toDouble() ?? 1.0,
      exerciseDaysPerWeek: (map['exerciseDaysPerWeek'] as num?)?.toInt() ?? 3,
      fitnessProficiency: map['fitnessProficiency'] ?? 'Beginner',
      age: map['age'] as int?,
      goalWeight: map['goalWeight'], // NEW FIELD
    );
  }

  UserProfile copyWith({
    String? activityLevel,
    String? primaryGoal,
    String? activeProgramId,
    String? biologicalSex,
    String? unitSystem,
    double? bodyFatPercentage,
    Map<String, dynamic>? weight,
    Map<String, dynamic>? height,
    Map<String, dynamic>? measurements,
    bool? onboardingCompleted,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    bool? prefersLowCarb,
    double? weeklyWeightLossGoal,
    int? exerciseDaysPerWeek,
    String? fitnessProficiency,
    int? age,
    Map<String, dynamic>? goalWeight, // NEW FIELD
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
      age: age ?? this.age,
      goalWeight: goalWeight ?? this.goalWeight, // NEW FIELD
    );
  }
} 