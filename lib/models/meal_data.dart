import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

part 'meal_data.g.dart';

@embedded
class FoodItem {
  String? name;
  double? protein; // Change: Transitioned to nullable to support Isar hydration
  double? carbs;
  double? fat;
  double? calories;
  String? notes;

  FoodItem({
    this.name,
    this.protein,
    this.carbs,
    this.fat,
    this.calories,
    this.notes,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? 'Unknown Item',
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'], // UPDATED FACTORY
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
      'notes': notes, // UPDATED TO_MAP
    };
  }
}

@embedded
class Meal {
  String? mealName;
  List<FoodItem>? foods;
  double? protein;
  double? carbs;
  double? fat;
  double? calories;
  String? aiInsight;

  Meal({
    this.mealName, this.foods, this.protein,
    this.carbs, this.fat, this.calories,
    this.aiInsight,
  });

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
      'foods': foods?.map((food) => food.toMap()).toList() ?? [], // Change: Added null-aware operator and fallback list
      'protein': protein, 'carbs': carbs, 'fat': fat,
      'calories': calories, 'aiInsight': aiInsight,
    };
  }
}


@embedded // Change: New class to handle Isar's lack of native Map<String, double> support
class MacroData {
  double protein = 0.0;
  double carbs = 0.0;
  double fat = 0.0;
}

@embedded // Change: New class to handle Isar's lack of native Map<String, List<FoodItem>> support
class MealSlot {
  String? slotName; // e.g., 'Breakfast'
  List<FoodItem>? items;
}

@collection // Change: Mark NutritionLog as a primary database table
class NutritionLog {
  Id isarId = Isar.autoIncrement; // Change: Added integer primary key for Isar

  @Index(unique: true, replace: true) // Change: Preserved string ID for sync consistency
  String id;
  DateTime date;
  
  List<MealSlot> meals; // Change: Replaced Map with Isar-compatible List of objects
  List<Meal> aiGeneratedMeals;
  double waterIntake;
  double totalCalories;
  MacroData? totalMacros; // Change: Replaced Map with typed object

 // ADDED BACK for compatibility
  bool isLowCarbDay;
  int? hungerRating;

  // Sync Metadata
  DateTime? lastSynced; // Change: Added for Stage 4 backup logic
  bool isDirty = false; // Change: Marker for local modifications

  NutritionLog({
    required this.id,
    required this.date,
    required this.meals,
    this.aiGeneratedMeals = const [],
    required this.waterIntake,
    required this.totalCalories,
    this.totalMacros, // Change: Removed required to allow null initialization
    this.isLowCarbDay = false,
    this.hungerRating,
    this.lastSynced,
    this.isDirty = false,
  });

  factory NutritionLog.empty({DateTime? date}) {
    final newDate = date ?? DateTime.now();
    return NutritionLog(
      id: DateFormat('yyyy-MM-dd').format(newDate),
      date: newDate,
      // Change: Initializing with List of MealSlots instead of Map literals
      meals: [
        MealSlot()..slotName = 'Breakfast'..items = [],
        MealSlot()..slotName = 'Lunch'..items = [],
        MealSlot()..slotName = 'Dinner'..items = [],
        MealSlot()..slotName = 'Snacks'..items = [],
      ],
      waterIntake: 0.0,
      totalCalories: 0.0,
      totalMacros: MacroData(), // Change: Initializing with typed object
    );
  }

 void recalculateTotals() {
    double tempTotalCalories = 0;
    double tempProtein = 0;
    double tempCarbs = 0;
    double tempFat = 0;
    
    // Change: Refactored loop to iterate over MealSlot list
    for (var slot in meals) {
      if (slot.items != null) {
        for (var food in slot.items!) {
          tempTotalCalories += food.calories ?? 0;
          tempProtein += food.protein ?? 0;
          tempCarbs += food.carbs ?? 0;
          tempFat += food.fat ?? 0;
        }
      }
    }

    totalCalories = tempTotalCalories;
    // Change: Assigned to MacroData object
    totalMacros = MacroData()
      ..protein = tempProtein
      ..carbs = tempCarbs
      ..fat = tempFat;
  }

  factory NutritionLog.fromMap(Map<String, dynamic> map) {
    // Change: Refactored to build a List of MealSlots instead of a Map
    List<MealSlot> parsedMeals = [];
    if (map['meals'] is Map) {
      (map['meals'] as Map).forEach((key, value) {
        if (value is List) {
          parsedMeals.add(MealSlot()
            ..slotName = key.toString()
            ..items = value.map((item) => FoodItem.fromMap(Map<String, dynamic>.from(item))).toList());
        }
      });
    }

    return NutritionLog(
      id: map['id'],
      // Change: Replaced Timestamp with DateTime/String handling for local-first compatibility
      date: map['date'] is DateTime 
          ? map['date'] 
          : (map['date'] is String ? DateTime.parse(map['date']) : DateTime.now()),
      meals: parsedMeals.isNotEmpty ? parsedMeals : [
        MealSlot()..slotName = 'Breakfast'..items = [],
        MealSlot()..slotName = 'Lunch'..items = [],
        MealSlot()..slotName = 'Dinner'..items = [],
        MealSlot()..slotName = 'Snacks'..items = [],
      ],
      aiGeneratedMeals: (map['aiGeneratedMeals'] as List<dynamic>?)
              ?.map((mealMap) => Meal.fromMap(Map<String, dynamic>.from(mealMap)))
              .toList() ?? [],
      waterIntake: (map['waterIntake'] as num?)?.toDouble() ?? 0.0,
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      // Change: Converted Map data into MacroData object
      totalMacros: map['totalMacros'] != null 
        ? (MacroData()
            ..protein = (map['totalMacros']['protein'] as num?)?.toDouble() ?? 0.0
            ..carbs = (map['totalMacros']['carbs'] as num?)?.toDouble() ?? 0.0
            ..fat = (map['totalMacros']['fat'] as num?)?.toDouble() ?? 0.0)
        : MacroData(),
      isLowCarbDay: map['isLowCarbDay'] ?? false,
      hungerRating: map['hungerRating'] as int?,
      // Change: Added sync metadata for Stage 4 logic
      lastSynced: map['lastSynced'] != null ? DateTime.parse(map['lastSynced']) : null,
      isDirty: map['isDirty'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    // SHIELD: Constructing a legacy-style Map for UI/Provider compatibility
    Map<String, dynamic> legacyMeals = {};
    for (var slot in meals) {
      legacyMeals[slot.slotName ?? 'Unknown'] = slot.items?.map((f) => f.toMap()).toList() ?? [];
    }

    return {
      'id': id,
      'date': date.toIso8601String(), // Change: Deterministic string for serialization
      'meals': legacyMeals, // SHIELD: Returning the map the rest of the app expects
      'aiGeneratedMeals': aiGeneratedMeals.map((meal) => meal.toMap()).toList(),
      'waterIntake': waterIntake,
      'totalCalories': totalCalories,
      'totalMacros': {
        'protein': totalMacros?.protein ?? 0.0,
        'carbs': totalMacros?.carbs ?? 0.0,
        'fat': totalMacros?.fat ?? 0.0,
      }, // SHIELD: Returning the map the rest of the app expects
      'isLowCarbDay': isLowCarbDay,
      'hungerRating': hungerRating,
      'lastSynced': lastSynced?.toIso8601String(),
      'isDirty': isDirty,
    };
  }
}