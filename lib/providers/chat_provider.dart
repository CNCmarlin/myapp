// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../models/assistant_response.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../providers/workout_provider.dart';
import '../services/assistant_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ChatProvider with ChangeNotifier {
  final AssistantService _assistantService = AssistantService();
  final FirestoreService _firestoreService = FirestoreService();
  final UserProfileProvider _userProfileProvider;
  final WorkoutProvider _workoutProvider;
  final AuthService _authService;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider({
    required UserProfileProvider userProfileProvider,
    required WorkoutProvider workoutProvider,
    required AuthService authService,
  })  : _userProfileProvider = userProfileProvider,
        _workoutProvider = workoutProvider,
        _authService = authService;

  Future<void> sendMessage(String text) async {
    final UserProfile? userProfile = _userProfileProvider.userProfile;
    final String? userId = _authService.currentUser?.uid;

    if (userProfile == null || userId == null) {
      _messages.insert(0,
          ChatMessage(text: "Error: User profile not loaded.", isUser: false));
      notifyListeners();
      return;
    }

    _messages.insert(0, ChatMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    // UPDATED: Fetch context before calling the assistant
    final lastWorkout = await _firestoreService.getLatestWorkoutLog(userId);
    final recentNutritionLogs =
        await _firestoreService.getRecentNutritionLogs(userId);

    final response = await _assistantService.getAssistantResponse(
      prompt: text,
      history: _messages,
      userProfile: userProfile,
      lastWorkout: lastWorkout, // Pass the context
      recentNutritionLogs: recentNutritionLogs, // Pass the context
    );

    switch (response.type) {
      case AssistantResponseType.text:
        _messages.insert(
            0, ChatMessage(text: response.textResponse!, isUser: false));
        break;
      case AssistantResponseType.program:
        if (response.programResponse != null) {
          try {
            final newProgramId = await _firestoreService.saveNewWorkoutProgram(
                userId, response.programResponse!);
            await _workoutProvider.refreshPrograms();
            await _userProfileProvider.updateActiveProgram(newProgramId);

            _messages.insert(
                0,
                ChatMessage(
                    text:
                        "I've created and saved the '${response.programResponse!.name}' program for you. I've also set it as your active program.",
                    isUser: false));
          } catch (e) {
            _messages.insert(
                0,
                ChatMessage(
                    text: "I created a program, but failed to save it: $e",
                    isUser: false));
          }
        }
        break;
    }

    _isLoading = false;
    notifyListeners();
  }
}