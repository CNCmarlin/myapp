import 'package:cloud_firestore/cloud_firestore.dart';

class Insight {
  final String id;
  final String summaryText;
  final DateTime generatedAt;

  Insight({
    required this.id,
    required this.summaryText,
    required this.generatedAt,
  });

  factory Insight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Insight(
      id: doc.id,
      summaryText: data['summaryText'] ?? 'No summary available.',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}