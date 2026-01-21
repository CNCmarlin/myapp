// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../models/assistant_response.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import '../providers/workout_provider.dart';
import '../services/assistant_service.dart';
import '../services/local_storage_service.dart';

class ChatProvider with ChangeNotifier {
  final AssistantService _assistantService;
  final LocalStorageService _localStorageService; // Change: Replaced Firestore with LocalStorage
  final UserProfileProvider _userProfileProvider;
  final WorkoutProvider _workoutProvider;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider({
    required UserProfileProvider userProfileProvider,
    required WorkoutProvider workoutProvider,
    required LocalStorageService localStorageService, // Change: Injected local storage
    required AssistantService assistantService,
  })  : _userProfileProvider = userProfileProvider,
        _workoutProvider = workoutProvider,
        _localStorageService = localStorageService,
        _assistantService = assistantService {
    _loadLocalHistory(); // Change: Auto-load history on initialization
  }

  Future<void> _loadLocalHistory() async {
    final history = await _localStorageService.getChatHistory();
    _messages.addAll(history);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final UserProfile? userProfile = _userProfileProvider.userProfile;

    if (userProfile == null) {
      _messages.insert(0, ChatMessage(text: "Error: User profile not loaded.", isUser: false, timestamp: DateTime.now()));
      notifyListeners();
      return;
    }

    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    _messages.insert(0, userMsg);
    await _localStorageService.saveChatMessage(userMsg); // Change: Immediate local save
    
    _userProfileProvider.triggerBackgroundSync();

    _isLoading = true;
    notifyListeners();

    // 🛡️ SHIELD: Swapped Firestore context fetch for Local disk read
    final lastWorkout = await _localStorageService.getLatestWorkout();
    final recentNutritionLogs = await _localStorageService.getRecentNutrition(3);

    final response = await _assistantService.getAssistantResponse(
      prompt: text,
      history: _messages.reversed.toList(),
      userProfile: userProfile,
      lastWorkout: lastWorkout, // Pass the context
      recentNutritionLogs: recentNutritionLogs, // Pass the context
    );

    switch (response.type) {
      case AssistantResponseType.text:
        // Fix: Created message with required timestamp and persisted it locally
        final assistantMsg = ChatMessage(
          text: response.textResponse!, 
          isUser: false, 
          timestamp: DateTime.now(),
        );
        _messages.insert(0, assistantMsg);
        await _localStorageService.saveChatMessage(assistantMsg);
        _userProfileProvider.triggerBackgroundSync();
        break;
      case AssistantResponseType.program:
        if (response.programResponse != null) {
          try {
            // Fix: Swapped legacy Firestore save for LocalStorage and removed userId dependency
            final program = response.programResponse!;
            await _localStorageService.saveWorkoutProgram(program);
            
            // Refresh and set active using the program's internal string ID
            await _workoutProvider.refreshPrograms();
            await _userProfileProvider.updateActiveProgram(program.id);

            final assistantMsg = ChatMessage(
              text: "I've created and saved the '${program.name}' program for you. I've also set it as your active program.",
              isUser: false,
              timestamp: DateTime.now(), // Fix: Added required timestamp for Isar
            );
            _messages.insert(0, assistantMsg);
            await _localStorageService.saveChatMessage(assistantMsg); // Fix: Persist AI response
            _userProfileProvider.triggerBackgroundSync();
          } catch (e) {
            final errorMsg = ChatMessage(
              text: "I created a program, but failed to save it locally: $e",
              isUser: false,
              timestamp: DateTime.now(),
            );
            _messages.insert(0, errorMsg);
          }
        }
        break;
    }

    _isLoading = false;
    notifyListeners();
  }
}