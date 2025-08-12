import 'package:flutter/material.dart';
import 'package:myapp/models/chat_message.dart';
import 'package:myapp/providers/chat_provider.dart';
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
                // This callback schedules the scroll to happen after the build is complete.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                });

                if (chatProvider.messages.isEmpty && !chatProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Ask me to create a workout program!\n\n(e.g., "Create a 3-day full body strength plan for me")',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  reverse: true, // This keeps the list scrolled to the bottom
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return _buildChatBubble(message);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
              color: message.isUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    // Watch the provider's loading state to disable the input bar
    final isLoading = context.watch<ChatProvider>().isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'Assistant is thinking...'
                    : 'Message your AI assistant...',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _handleSendPressed(),
            ),
          ),
          const SizedBox(width: 8),
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator())
              : IconButton(
                  icon: const Icon(Icons.send), onPressed: _handleSendPressed),
        ],
      ),
    );
  }
}