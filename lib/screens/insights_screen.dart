// lib/screens/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/insight_data.dart';
import '../providers/insights_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  void _showGenerationOptions(BuildContext context) {
    final provider = context.read<InsightsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Generate Weekly Workout Report'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewWorkoutInsight(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fastfood_outlined),
                title: const Text('Generate Weekly Nutrition Report'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewNutritionInsight(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Generate Weekly Summary'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewSummaryInsight(context, isMonthly: false);
                },
              ),
               ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Generate Monthly Summary'),
                onTap: () {
                  Navigator.pop(context);
                  provider.generateNewSummaryInsight(context, isMonthly: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Workout, Nutrition, Summary
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Workout'),
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Summary'),
                ],
              ),
            ],
          ),
        ),
        body: Consumer<InsightsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                // Workout Insights Tab
                _buildInsightList(context, provider.workoutInsights,
                    'Generate your first workout insight using the button below.'),
                // Nutrition Insights Tab
                _buildInsightList(context, provider.nutritionInsights,
                    'Generate your first nutrition insight using the button below.'),
                // Summary Insights Tab
                _buildInsightList(context, provider.summaryInsights,
                    'Generate your first summary insight using the button below.'),
              ],
            );
          },
        ),
        
      ),
    );
  }

  Widget _buildInsightList(
      BuildContext context, List<Insight> insights, String emptyMessage) {
    if (insights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return _buildInsightCard(context, insight);
      },
    );
  }

  Widget _buildInsightCard(BuildContext context, Insight insight) {
    IconData icon;
    Color color;
    switch (insight.insightType) {
      case InsightType.performanceTrend:
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case InsightType.nutritionCorrelation:
        icon = Icons.restaurant_menu;
        color = Colors.orange;
        break;
      case InsightType.milestone:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      default:
        icon = Icons.lightbulb_outline;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Generated on ${DateFormat.yMMMd().format(insight.generatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            MarkdownBody(data: insight.summaryText),
          ],
        ),
      ),
    );
  }
}