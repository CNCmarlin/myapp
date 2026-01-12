// lib/utils/nutrition_utils.dart

/// Determines the meal category (e.g., 'Breakfast', 'Lunch') from a given
/// AI-generated meal name.
///
/// This function is case-insensitive and defaults to 'Snacks' if no other
/// category is matched.
String getMealTypeFromName(String aiMealName) {
  final lowerCaseName = aiMealName.toLowerCase();
  if (lowerCaseName.contains('breakfast')) return 'Breakfast';
  if (lowerCaseName.contains('lunch')) return 'Lunch';
  if (lowerCaseName.contains('dinner')) return 'Dinner';
  return 'Snacks'; // Default case
}