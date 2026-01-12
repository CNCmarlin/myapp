// lib/services/insights_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class InsightsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // NEW: Specific on-demand function for summary insights
  Future<String> generateSummaryInsight({required bool isMonthly}) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('generateSummaryInsight');
      final result = await callable.call({'isMonthly': isMonthly});
      return result.data['message'] as String;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions Exception: ${e.code} - ${e.message}');
      return 'Error: ${e.message}';
    } catch (e) {
      debugPrint('Generic Exception: $e');
      return 'An unknown error occurred.';
    }
  }

  Future<String> generateWorkoutInsight() async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('generateWorkoutInsight');
      final result = await callable.call();
      return result.data['message'] as String;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions Exception: ${e.code} - ${e.message}');
      return 'Error: ${e.message}';
    } catch (e) {
      debugPrint('Generic Exception: $e');
      return 'An unknown error occurred.';
    }
  }

  Future<String> generateNutritionInsight() async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('generateNutritionInsight');
      final result = await callable.call();
      return result.data['message'] as String;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions Exception: ${e.code} - ${e.message}');
      return 'Error: ${e.message}';
    } catch (e) {
      debugPrint('Generic Exception: $e');
      return 'An unknown error occurred.';
    }
  }

  // DEPRECATED: This will be removed once all new functions are in place
  Future<String> generateNewWeeklyInsight() async {
     try {
       final HttpsCallable callable = _functions.httpsCallable('generateWeeklyInsight');
       final result = await callable.call();
       return result.data['message'] as String;
     } on FirebaseFunctionsException catch (e) {
       debugPrint('Firebase Functions Exception: ${e.code} - ${e.message}');
       return 'Error: ${e.message}';
     } catch (e) {
       debugPrint('Generic Exception: $e');
       return 'An unknown error occurred.';
     }
   }
}