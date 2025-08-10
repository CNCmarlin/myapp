import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/insights_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to easily react to changes in the provider's state
    return Consumer<InsightsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Button to generate a new insight
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  // Disable the button while an insight is being generated
                  onPressed: provider.isGenerating
                      ? null
                      : () => provider.generateNewInsight(),
                  icon: provider.isGenerating
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(provider.isGenerating
                      ? 'Generating Your Insight...'
                      : 'Generate New Weekly Insight'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Past Insights',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                // Display a loading indicator while fetching the list
                if (provider.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                // Display a message if no insights are available
                else if (provider.insights.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No insights have been generated yet. Tap the button to create your first weekly summary!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                // Display the list of insights
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.insights.length,
                      itemBuilder: (context, index) {
                        final insight = provider.insights[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ExpansionTile(
                            title: Text(
                              'Week of ${DateFormat.yMMMd().format(insight.generatedAt)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                // Use the Markdown widget to render the AI's response
                                child: MarkdownBody(data: insight.summaryText),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}