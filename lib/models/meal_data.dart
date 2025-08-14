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
      'name': name,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
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
    required this.mealName,
    required this.foods,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    this.aiInsight,
  });
  
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
    List<FoodItem> foodItems = [];
    
    if (map['foods'] is List) {
      foodItems = (map['foods'] as List<dynamic>)
          .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (map['foods'] is String) {
      foodItems.add(FoodItem(
        name: map['foods'],
        protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
        calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    return Meal(
      mealName: map['mealName'] ?? 'Unnamed Meal',
      foods: foodItems,
      // FIX: Made these casts null-safe to prevent crashes
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
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
      'aiInsight': aiInsight,
    };
  }
}

class NutritionLog {
  String id; // YYYY-MM-DD
  DateTime date;
  List<Meal> meals;
  double waterIntake;
  bool isLowCarbDay;
  double totalCalories;
  Map<String, double> totalMacros;
  int? hungerRating;

  NutritionLog({
    required this.id,
    required this.date,
    required this.meals,
    required this.waterIntake,
    required this.isLowCarbDay,
    required this.totalCalories,
    required this.totalMacros,
    this.hungerRating,
  });

  factory NutritionLog.empty({DateTime? date}) {
    final newDate = date ?? DateTime.now();
    return NutritionLog(
      id: DateFormat('yyyy-MM-dd').format(newDate),
      date: newDate,
      meals: [],
      waterIntake: 0.0,
      isLowCarbDay: false,
      totalCalories: 0.0,
      totalMacros: {'protein': 0, 'carbs': 0, 'fat': 0},
      hungerRating: null,
    );
  }

  void recalculateTotals() {
    double tempTotalCalories = 0;
    Map<String, double> tempTotalMacros = {'protein': 0, 'carbs': 0, 'fat': 0};
    for (var meal in meals) {
      tempTotalCalories += meal.calories;
      tempTotalMacros['protein'] =
          (tempTotalMacros['protein'] ?? 0) + meal.protein;
      tempTotalMacros['carbs'] = (tempTotalMacros['carbs'] ?? 0) + meal.carbs;
      tempTotalMacros['fat'] = (tempTotalMacros['fat'] ?? 0) + meal.fat;
    }
    totalCalories = tempTotalCalories;
    totalMacros = tempTotalMacros;
  }

  factory NutritionLog.fromMap(Map<String, dynamic> map) {
    return NutritionLog(
      id: map['id'],
      date: (map['date'] as Timestamp).toDate(),
      meals: (map['meals'] as List<dynamic>)
          .map((mealMap) => Meal.fromMap(mealMap as Map<String, dynamic>))
          .toList(),
      waterIntake: (map['waterIntake'] as num).toDouble(),
      isLowCarbDay: map['isLowCarbDay'],
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalMacros: Map<String, double>.from(map['totalMacros'] ?? {}),
      hungerRating: map['hungerRating'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'waterIntake': waterIntake,
      'isLowCarbDay': isLowCarbDay,
      'totalCalories': totalCalories,
      'totalMacros': totalMacros,
      'hungerRating': hungerRating,
    };
  }
}