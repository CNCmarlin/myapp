import 'package:isar/isar.dart';

part 'chat_message.g.dart';

@collection
class ChatMessage {
  Id isarId = Isar.autoIncrement; // Change: Required for Isar collection

  final String text;
  final bool isUser;
  final DateTime timestamp; // Change: Added for chronological sorting

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}