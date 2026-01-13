// lib/providers/insights_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/insight_data.dart';
import '../services/auth_service.dart';
import '../services/insights_service.dart';
import '../services/local_storage_service.dart';

// Enum to track which specific insight is being generated
enum InsightGenerationType { none, workout, nutrition, summary }

class InsightsProvider with ChangeNotifier {
  final AuthService _authService;
  final LocalStorageService _localStorageService; 
  final InsightsService _insightsService;

  InsightsProvider({
    required AuthService authService,
    required LocalStorageService localStorageService,
    required InsightsService insightsService, // Fix: Injected to resolve missing argument errors
  })  : _authService = authService,
        _localStorageService = localStorageService,
        _insightsService = insightsService {
    _subscribeToInsights();
  }

  StreamSubscription? _insightsSubscription;

  List<Insight> _allInsights = [];
  bool _isLoading = false;
  // NEW: State for on-demand generation
  InsightGenerationType _generatingType = InsightGenerationType.none;

  List<Insight> get allInsights => _allInsights;
  bool get isLoading => _isLoading;
  InsightGenerationType get generatingType => _generatingType;

  // Filtered getters for the UI tabs
  List<Insight> get workoutInsights => _allInsights
      .where((i) => i.insightType == InsightType.performanceTrend)
      .toList();

  List<Insight> get nutritionInsights => _allInsights
      .where((i) => i.insightType == InsightType.nutritionCorrelation)
      .toList();

  List<Insight> get summaryInsights => _allInsights
      .where((i) =>
          i.insightType == InsightType.milestone ||
          i.insightType == InsightType.weeklySummary)
      .toList();

  void _subscribeToInsights() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();
    _insightsSubscription?.cancel();

    _insightsSubscription = _localStorageService.watchInsights().listen((insightsData) {
           // --- DEBUG LOGGING ---
      if (kDebugMode) {
        print('[DEBUG] InsightsProvider stream updated. Received ${insightsData.length} insights.');
      }
      // --- END DEBUG LOGGING ---
      _allInsights = insightsData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) {
        print("Error in insights stream: $error");
      }
      _isLoading = false;
      _allInsights = [];
      notifyListeners();
    });
  }

   Future<void> generateNewWorkoutInsight(BuildContext context) async {
    _generatingType = InsightGenerationType.workout;
    notifyListeners();

    final result = await _insightsService.generateWorkoutInsight();
    if (result.startsWith('Error:') && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }

    _generatingType = InsightGenerationType.none;
    notifyListeners();
  }

  // UPDATED: Now accepts a BuildContext and handles errors
  Future<void> generateNewNutritionInsight(BuildContext context) async {
    _generatingType = InsightGenerationType.nutrition;
    notifyListeners();

    final result = await _insightsService.generateNutritionInsight();
    if (result.startsWith('Error:') && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }

    _generatingType = InsightGenerationType.none;
    notifyListeners();
  }

  // UPDATED: Now accepts a BuildContext and handles errors
  Future<void> generateNewSummaryInsight(BuildContext context, {bool isMonthly = false}) async {
    _generatingType = InsightGenerationType.summary;
    notifyListeners();

    final result = await _insightsService.generateSummaryInsight(isMonthly: isMonthly);
    if (result.startsWith('Error:') && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }

    _generatingType = InsightGenerationType.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _insightsSubscription?.cancel();
    super.dispose();
  }
}