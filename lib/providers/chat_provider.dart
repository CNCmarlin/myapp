import 'package:flutter/material.dart';
import 'package:myapp/models/chat_message.dart';
import 'package:myapp/services/assistant_service.dart';

class ChatProvider with ChangeNotifier {
  final AssistantService _assistantService = AssistantService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    // Optimistically add the user's message
    _messages.insert(0, ChatMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    // Get the AI's response
    final String responseText = await _assistantService.sendMessage(text);

    // Add the AI's message
    _messages.insert(0, ChatMessage(text: responseText, isUser: false));
    _isLoading = false;
    notifyListeners();
  }
}