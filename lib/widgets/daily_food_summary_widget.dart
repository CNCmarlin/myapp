import 'package:flutter/material.dart';
import 'package:myapp/models/meal_data.dart';

class DailyFoodSummaryWidget extends StatelessWidget {
  final List<Meal> meals;

  const DailyFoodSummaryWidget({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalCalories = 0;

    for (var meal in meals) {
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
      totalCalories += meal.calories;
    }

    String proteinFeedback;
    if (totalProtein >= 180 && totalProtein <= 200) {
      proteinFeedback = "Protein target met!";
    } else if (totalProtein > 200) {
      proteinFeedback = "Exceeded protein target.";
    } else {
      proteinFeedback = "Below protein target.";
    }

    String calorieFeedback;
    if (totalCalories >= 1800 && totalCalories <= 2100) {
      calorieFeedback = "Calories are on track.";
    } else if (totalCalories > 2100) {
      calorieFeedback = "Exceeded calorie target.";
    } else {
      calorieFeedback = "Below calorie target.";
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Daily Totals:",
              style: Theme.of(context).textTheme.titleLarge,
            ), // L50: Changed from headline6
            const SizedBox(height: 8.0),
            Text("Protein: ${totalProtein.toStringAsFixed(1)} g"),
            Text("Carbs: ${totalCarbs.toStringAsFixed(1)} g"),
            Text("Fat: ${totalFat.toStringAsFixed(1)} g"),
            Text("Calories: ${totalCalories.toStringAsFixed(1)} kcal"),
            const SizedBox(height: 16.0), // L60: Changed from subtitle1
            Text(
              "Feedback:",
              style: Theme.of(context).textTheme.titleMedium,
            ), // Considered using titleMedium, but subtitle1 is also a valid style
            const SizedBox(height: 4.0),
            Text(proteinFeedback),
            Text(calorieFeedback),
          ],
        ),
      ),
    );
  }
}