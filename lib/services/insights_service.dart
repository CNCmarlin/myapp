// lib/services/insights_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class InsightsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> generateNewWeeklyInsight() async {
    try {
      // For development, you might want to point to the emulator
      // _functions.useFunctionsEmulator('localhost', 5001);
      
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