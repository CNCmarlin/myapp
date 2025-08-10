import 'package:cloud_firestore/cloud_firestore.dart';

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

  // NEW: Fields for nutrition goals
  double? targetCalories;
  double? targetProtein;
  double? targetCarbs;
  double? targetFat;

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
    // NEW: Add to constructor with default values
    this.targetCalories = 0.0,
    this.targetProtein = 0.0,
    this.targetCarbs = 0.0,
    this.targetFat = 0.0,
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
      // NEW: Add to toMap
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
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
      // NEW: Add to fromMap with null-safe defaults
      targetCalories: (map['targetCalories'] as num?)?.toDouble() ?? 0.0,
      targetProtein: (map['targetProtein'] as num?)?.toDouble() ?? 0.0,
      targetCarbs: (map['targetCarbs'] as num?)?.toDouble() ?? 0.0,
      targetFat: (map['targetFat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data);
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
    // NEW: Add to copyWith
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
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
      // NEW: Add to copyWith return
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
    );
  }
}