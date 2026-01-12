// lib/models/insight_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum to define the type of insight for UI rendering
enum InsightType {
  performanceTrend,
  nutritionCorrelation,
  milestone,
  weeklySummary,
  unknown,
}

class Insight {
  final String id;
  final String title;
  final String summaryText;
  final InsightType insightType;
  final DateTime generatedAt;
  final Map<String, dynamic> relatedData;
  final bool isRead;

  Insight({
    required this.id,
    required this.title,
    required this.summaryText,
    required this.insightType,
    required this.generatedAt,
    this.relatedData = const {},
    this.isRead = false,
  });

  factory Insight.fromMap(Map<String, dynamic> map, String docId) {
    return Insight(
      id: docId,
      title: map['title'] ?? 'Insight',
      summaryText: map['summaryText'] ?? '',
      insightType: _stringToInsightType(map['insightType']),
      generatedAt: (map['generatedAt'] as Timestamp).toDate(),
      relatedData: Map<String, dynamic>.from(map['relatedData'] ?? {}),
      isRead: map['isRead'] ?? false,
    );
  }

  static InsightType _stringToInsightType(String? typeStr) {
    switch (typeStr) {
      case 'PERFORMANCE_TREND':
        return InsightType.performanceTrend;
      case 'NUTRITION_CORRELATION':
        return InsightType.nutritionCorrelation;
      case 'MILESTONE':
        return InsightType.milestone;
      case 'WEEKLY_SUMMARY':
        return InsightType.weeklySummary;
      default:
        return InsightType.unknown;
    }
  }
}