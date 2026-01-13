// lib/models/insight_data.dart

import 'dart:convert';

import 'package:isar/isar.dart';

part 'insight_data.g.dart';

// Enum to define the type of insight for UI rendering
enum InsightType {
  performanceTrend,
  nutritionCorrelation,
  milestone,
  weeklySummary,
  unknown,
}

@collection
class Insight {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String id;
  String title;
  String summaryText;

  @enumerated // 🛡️ SHIELD: Isar native enum support
  InsightType insightType;

  DateTime generatedAt;
  bool isRead;

  String? relatedDataJson;

  Insight({
    required this.id,
    required this.title,
    required this.summaryText,
    required this.insightType,
    required this.generatedAt,
    this.relatedDataJson,
    this.isRead = false,
  });


  factory Insight.fromMap(Map<String, dynamic> map, String docId) {
    return Insight(
      id: docId,
      title: map['title'] ?? 'Insight',
      summaryText: map['summaryText'] ?? '',
      insightType: _stringToInsightType(map['insightType']),
      // Fix: Handles case where date is stored as ISO String on local disk
      generatedAt: map['generatedAt'] is DateTime 
          ? map['generatedAt'] 
          : DateTime.tryParse(map['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      // Fix: Map the incoming dynamic map to our localized Json string field
      relatedDataJson: map['relatedDataJson'] ?? jsonEncode(map['relatedData'] ?? {}),
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