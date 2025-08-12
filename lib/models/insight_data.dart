import 'package:cloud_firestore/cloud_firestore.dart';

class Insight {
  final DateTime generatedAt;
  final String summaryText;
  final String type;

  Insight({
    required this.generatedAt,
    required this.summaryText,
    required this.type,
  });

  factory Insight.fromMap(Map<String, dynamic> map) {
    return Insight(
      // Handles both Timestamp and ISO 8601 string for generatedAt
      generatedAt: (map['generatedAt'] is Timestamp)
          ? (map['generatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['generatedAt'] as String? ?? DateTime.now().toIso8601String()),
      summaryText: map['summaryText'] ?? '',
      type: map['type'] ?? 'weekly',
    );
  }
  
  // FIX: Added fromFirestore constructor for compatibility with the provider.
  factory Insight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Insight.fromMap(data);
  }
}