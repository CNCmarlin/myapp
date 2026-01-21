class FitnessMath {
  static double calculateBMR(double weightKg, double heightCm, int age, String sex) {
    if (sex.toLowerCase() == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }

  static double calculateTDEE(double bmr, String activityLevel, int exerciseDays) {
    const multipliers = {
      'sedentary': 1.2,
      'lightly active': 1.375,
      'moderately active': 1.55,
      'very active': 1.725,
      'extra active': 1.9,
    };
    final baseTdee = bmr * (multipliers[activityLevel.toLowerCase()] ?? 1.2);
    
    // Rationale: Add ~400 calories per session averaged over the week
    return baseTdee + ((exerciseDays * 400) / 7);
  }

  static double calculateGoalAdjustment(double weeklyGoalLbs, String goalType) {
    // 3500 calories per lb / 7 days = 500 calories per lb/week deficit
    final dailyAdjustment = (weeklyGoalLbs * 3500) / 7;
    return goalType.toLowerCase() == 'gain' ? dailyAdjustment : -dailyAdjustment;
  }
}