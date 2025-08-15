import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  String name;
  double protein;
  double carbs;
  double fat;
  double calories;

  FoodItem({
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? 'Unknown Item',
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name, 'protein': protein, 'carbs': carbs,
      'fat': fat, 'calories': calories,
    };
  }
}

class Meal {
  String mealName;
  List<FoodItem> foods;
  double protein;
  double carbs;
  double fat;
  double calories;
  String? aiInsight;

  Meal({
    required this.mealName, required this.foods, required this.protein,
    required this.carbs, required this.fat, required this.calories,
    this.aiInsight,
  });

  // ADDED BACK for compatibility with AIService
  factory Meal.fromCloudFunction(Map<String, dynamic> data) {
    dynamic deepCast(dynamic value) {
      if (value is Map) {
        return value.map((key, val) => MapEntry(key.toString(), deepCast(val)));
      }
      if (value is List) {
        return value.map((e) => deepCast(e)).toList();
      }
      return value;
    }
    final safeData = deepCast(data);
    return Meal.fromMap(safeData as Map<String, dynamic>);
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      mealName: map['mealName'] ?? 'Unnamed Meal',
      foods: (map['foods'] as List<dynamic>?)
              ?.map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
              .toList() ?? [],
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      aiInsight: map['aiInsight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mealName': mealName,
      'foods': foods.map((food) => food.toMap()).toList(),
      'protein': protein, 'carbs': carbs, 'fat': fat,
      'calories': calories, 'aiInsight': aiInsight,
    };
  }
}

class NutritionLog {
  String id;
  DateTime date;
  Map<String, List<FoodItem>> meals;
  List<Meal> aiGeneratedMeals;
  double waterIntake;
  double totalCalories;
  Map<String, double> totalMacros;

  // ADDED BACK for compatibility
  bool isLowCarbDay;
  int? hungerRating;

  NutritionLog({
    required this.id,
    required this.date,
    required this.meals,
    this.aiGeneratedMeals = const [],
    required this.waterIntake,
    required this.totalCalories,
    required this.totalMacros,
    this.isLowCarbDay = false,
    this.hungerRating,
  });

  factory NutritionLog.empty({DateTime? date}) {
    final newDate = date ?? DateTime.now();
    return NutritionLog(
      id: DateFormat('yyyy-MM-dd').format(newDate),
      date: newDate,
      meals: { 'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': [] },
      waterIntake: 0.0,
      totalCalories: 0.0,
      totalMacros: {'protein': 0, 'carbs': 0, 'fat': 0},
    );
  }

  void recalculateTotals() {
    double tempTotalCalories = 0;
    Map<String, double> tempTotalMacros = {'protein': 0, 'carbs': 0, 'fat': 0};
    
    meals.forEach((mealName, foodItems) {
      for (var food in foodItems) {
        tempTotalCalories += food.calories;
        tempTotalMacros['protein'] = (tempTotalMacros['protein'] ?? 0) + food.protein;
        tempTotalMacros['carbs'] = (tempTotalMacros['carbs'] ?? 0) + food.carbs;
        tempTotalMacros['fat'] = (tempTotalMacros['fat'] ?? 0) + food.fat;
      }
    });

    totalCalories = tempTotalCalories;
    totalMacros = tempTotalMacros;
  }

  factory NutritionLog.fromMap(Map<String, dynamic> map) {
    Map<String, List<FoodItem>> parsedMeals = {};
    if (map['meals'] is Map) {
      (map['meals'] as Map).forEach((key, value) {
        if (value is List) {
          parsedMeals[key.toString()] = value.map((item) =>
            FoodItem.fromMap(item as Map<String, dynamic>)).toList();
        }
      });
    }

    return NutritionLog(
      id: map['id'],
      date: (map['date'] as Timestamp).toDate(),
      meals: parsedMeals.isNotEmpty ? parsedMeals : {
        'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': [],
      },
      aiGeneratedMeals: (map['aiGeneratedMeals'] as List<dynamic>?)
              ?.map((mealMap) => Meal.fromMap(mealMap as Map<String, dynamic>))
              .toList() ?? [],
      waterIntake: (map['waterIntake'] as num?)?.toDouble() ?? 0.0,
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalMacros: Map<String, double>.from(map['totalMacros'] ?? {}),
      // ADDED BACK for compatibility
      isLowCarbDay: map['isLowCarbDay'] ?? false,
      hungerRating: map['hungerRating'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'meals': meals.map((key, value) => MapEntry(key, value.map((food) => food.toMap()).toList())),
      'aiGeneratedMeals': aiGeneratedMeals.map((meal) => meal.toMap()).toList(),
      'waterIntake': waterIntake,
      'totalCalories': totalCalories,
      'totalMacros': totalMacros,
      // ADDED BACK for compatibility
      'isLowCarbDay': isLowCarbDay,
      'hungerRating': hungerRating,
    };
  }
}