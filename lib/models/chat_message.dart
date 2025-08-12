class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  // FIX: Added the toMap() method for serialization.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
    };
  }
}