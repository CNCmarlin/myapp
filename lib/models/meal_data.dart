import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// NEW: A model for individual food items within a meal.
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
  List<FoodItem> foods; // CHANGED: from String to List<FoodItem>
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

  factory Meal.fromMap(Map<String, dynamic> map) {
    List<FoodItem> foodItems = [];
    
    // THIS IS THE FIX: Check the type of the 'foods' field
    if (map['foods'] is List) {
      // If it's a List, parse it the new way
      foodItems = (map['foods'] as List<dynamic>)
          .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (map['foods'] is String) {
      // If it's a String, we know it's old data.
      // We'll create a single FoodItem to hold the old data.
      foodItems.add(FoodItem(
        name: map['foods'], // The old string becomes the item name
        protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
        calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    return Meal(
      mealName: map['mealName'],
      foods: foodItems, // Use the parsed or migrated list
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      aiInsight: map['aiInsight'],
    );
  }

  // FIX: Added the missing toMap() method.
  // This converts the Meal object into a Map so it can be stored in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'mealName': mealName,
      // We also need to convert each FoodItem in the list back to a map.
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

  // In lib/models/meal_data.dart, inside the NutritionLog class

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
