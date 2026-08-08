import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/formatter_service.dart';
import '../widgets/thought_bubble.dart';

class ChatViewerScreen extends StatefulWidget {
  final Note note;

  const ChatViewerScreen({super.key, required this.note});

  @override
  State<ChatViewerScreen> createState() => _ChatViewerScreenState();
}

class _ChatViewerScreenState extends State<ChatViewerScreen> {
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final storage = context.read<StorageService>();
    final messages = await storage.readChatMessages(widget.note);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${_messages.length} messages',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _convertFromGemini,
            tooltip: 'Import Gemini Format',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportChat,
            tooltip: 'Export',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit JSON'),
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
            ],
            onSelected: (value) {
              // TODO: Handle menu actions
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? _buildEmptyState()
              : _buildChatView(settings),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import a Gemini export to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _convertFromGemini,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Gemini Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(SettingsService settings) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: settings.chatBubbleStyle == 'spacious' ? 24 : 12,
            ),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageCard(message, settings, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(ChatMessage message, SettingsService settings, int index) {
    final isCompact = settings.chatBubbleStyle == 'compact';
    final isSpacious = settings.chatBubbleStyle == 'spacious';
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isSpacious ? 24 : isCompact ? 8 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User message card
          Card(
            margin: const EdgeInsets.only(left: 48),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.person, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (settings.showTimestamps)
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.userMessage,
                    style: TextStyle(
                      fontSize: settings.fontSize,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Thoughts (if enabled)
          if (settings.showThoughts && message.thoughts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ThoughtBubble(thoughts: message.thoughts),
            ),
          
          // Model response card
          Card(
            margin: const EdgeInsets.only(right: 48),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        child: const Icon(Icons.smart_toy, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Model',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 12 : 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.modelResponse,
                    style: TextStyle(
                      fontSize: settings.fontSize,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: Duration(milliseconds: 300 * settings.animationSpeed.toInt()),
      delay: Duration(milliseconds: 50 * index % 5),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: Duration(milliseconds: 300 * settings.animationSpeed.toInt()),
      curve: Curves.easeOut,
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _convertFromGemini() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Gemini Export'),
        content: const Text(
          'Paste your Gemini export JSON below to convert it to the chat format.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showImportDialog();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste Gemini JSON'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Paste your Gemini export JSON here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _processGeminiImport(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _processGeminiImport(String jsonText) {
    try {
      final json = Map<String, dynamic>.from(
        const JsonDecoder().convert(jsonText) as Map,
      );
      
      if (FormatterService.isGeminiFormat(json)) {
        final chatJson = FormatterService.convertGeminiToChat(json);
        final messages = FormatterService.parseChatJson(chatJson);
        
        setState(() {
          _messages = messages;
        });
        
        // Save to storage
        context.read<StorageService>().saveChatMessages(widget.note, messages);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully imported chat!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Gemini export format'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing JSON: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportChat() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon!')),
    );
  }
}
