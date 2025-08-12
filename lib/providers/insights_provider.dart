import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:myapp/models/insight_data.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/firestore_service.dart'; // Import FirestoreService
import 'package:myapp/services/insights_service.dart';

class InsightsProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService; // Use our service layer
  final InsightsService _insightsService = InsightsService();
  
  StreamSubscription? _insightsSubscription; // To manage the real-time listener

  List<Insight> _insights = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  List<Insight> get insights => _insights;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;

  InsightsProvider({
    required AuthService authService,
    required FirestoreService firestoreService, // Inject the service
  })  : _authService = authService,
        _firestoreService = firestoreService {
    _subscribeToInsights(); // Call the new subscription method
  }

  // NEW: Real-time subscription method
  void _subscribeToInsights() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    // Cancel any existing subscription to prevent memory leaks
    _insightsSubscription?.cancel();
    
    // Use the secure, centralized method from FirestoreService
    _insightsSubscription = _firestoreService.getInsightsStream(userId).listen((insightsData) {
      _insights = insightsData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error in insights stream: $error");
      _isLoading = false;
      _insights = [];
      notifyListeners();
    });
  }

  Future<void> generateNewInsight() async {
    _isGenerating = true;
    notifyListeners();

    await _insightsService.generateNewWeeklyInsight();
    
    // We no longer need to manually fetch. The stream will update automatically.
    // await fetchInsights(); 

    _isGenerating = false;
    notifyListeners();
  }

  // Clean up the subscription when the provider is disposed
  @override
  void dispose() {
    _insightsSubscription?.cancel();
    super.dispose();
  }
}