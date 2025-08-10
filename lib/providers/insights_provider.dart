// lib/providers/insights_provider.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/insight_data.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // We need this for the query
import 'package:myapp/services/insights_service.dart';

class InsightsProvider with ChangeNotifier {
  final AuthService _authService;
  final InsightsService _insightsService = InsightsService();
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Direct instance for querying

  List<Insight> _insights = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  List<Insight> get insights => _insights;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;

  InsightsProvider({required AuthService authService}) : _authService = authService {
    fetchInsights();
  }

  Future<void> fetchInsights() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('insights')
          .orderBy('generatedAt', descending: true)
          .get();

      _insights = snapshot.docs.map((doc) => Insight.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching insights: $e");
      _insights = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> generateNewInsight() async {
    _isGenerating = true;
    notifyListeners();

    await _insightsService.generateNewWeeklyInsight();

    // After generating, refresh the list to show the new one.
    await fetchInsights();

    _isGenerating = false;
    notifyListeners();
  }
}