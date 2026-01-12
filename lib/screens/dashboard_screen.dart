// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendPressed() {
    if (_textController.text.trim().isNotEmpty) {
      context.read<ChatProvider>().sendMessage(_textController.text.trim());
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                });

                if (chatProvider.messages.isEmpty && !chatProvider.isLoading) {
                  // UPDATED: New welcome message and suggestion chips
                  return _buildWelcomeMessage();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  reverse: true,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return _buildChatBubble(message);
                  },
                );
              },
            ),
          ),
          _buildAiInputField(), // UPDATED to use new input bar
        ],
      ),
    );
  }
  
  // NEW: Extracted welcome message widget
  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Your AI Fitness Coach',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything about fitness, nutrition, or ask me to create a workout program for you!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                label: const Text('Create a workout'),
                onPressed: () => context.read<ChatProvider>().sendMessage('Create a 4-day workout plan for me'),
              ),
              ActionChip(
                label: const Text('Protein for muscle building?'),
                onPressed: () => context.read<ChatProvider>().sendMessage('How much protein should I eat to build muscle?'),
              ),
              ActionChip(
                label: const Text('Best cardio for fat loss?'),
                onPressed: () => context.read<ChatProvider>().sendMessage('What is the best type of cardio for fat loss?'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Card( // Use Card for a more modern look
        elevation: 2,
        color: message.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            message.text,
            style: TextStyle(
                color: message.isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  // UPDATED: Using the sleek input bar from Nutrition screen
  Widget _buildAiInputField() {
    final isAnalyzing = context.watch<ChatProvider>().isLoading;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _textController,
            enabled: !isAnalyzing,
            decoration: InputDecoration(
              hintText: isAnalyzing
                  ? 'Analyzing...'
                  : 'Message your AI assistant...',
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: isAnalyzing
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _handleSendPressed,
                    ),
            ),
            onSubmitted: (_) => _handleSendPressed(),
          ),
        ),
      ),
    );
  }
}