import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/formatter_service.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_button.dart';
import '../widgets/glass/animated_gradient_background.dart';
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 60),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC))
                          .withOpacity(0.8),
                      (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC))
                          .withOpacity(0.4),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.note.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                '${_messages.length} messages',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildAppBarButton(
                          context,
                          Icons.import_export_rounded,
                          () => _convertFromGemini(),
                        ),
                        _buildAppBarButton(
                          context,
                          Icons.download_rounded,
                          () => _exportChat(),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty
                ? _buildEmptyState()
                : _buildChatView(settings),
      ),
    );
  }

  Widget _buildAppBarButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
          ).animate().scale(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Import a Gemini export to get started',
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
          GlassButton(
            onPressed: _convertFromGemini,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Import Gemini Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildChatView(SettingsService settings) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageCard(message, settings, index);
      },
    );
  }

  Widget _buildMessageCard(
      ChatMessage message, SettingsService settings, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          GlassCard(
            margin: const EdgeInsets.only(left: 32),
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message.userMessage,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 30 * (index % 10)),
                duration: const Duration(milliseconds: 400),
              ).slideX(
                begin: 0.1,
                end: 0,
                delay: Duration(milliseconds: 30 * (index % 10)),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              ),

          // Thoughts (if enabled)
          if (settings.showThoughts && message.thoughts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
              child: ThoughtBubble(thoughts: message.thoughts),
            ),

          // Model response card
          GlassCard(
            margin: const EdgeInsets.only(right: 32),
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.15),
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.05),
                    ]
                  : [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.2),
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.1),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.2),
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Model',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 12 : 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message.modelResponse,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 30 * (index % 10) + 15),
                duration: const Duration(milliseconds: 400),
              ).slideX(
                begin: -0.1,
                end: 0,
                delay: Duration(milliseconds: 30 * (index % 10) + 15),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _convertFromGemini() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Paste Gemini JSON'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Paste your Gemini export JSON here...',
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
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
        jsonDecode(jsonText) as Map,
      );

      if (FormatterService.isGeminiFormat(json)) {
        final chatJson = FormatterService.convertGeminiToChat(json);
        final messages = FormatterService.parseChatJson(chatJson);

        setState(() {
          _messages = messages;
        });

        context.read<StorageService>().saveChatMessages(widget.note, messages);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully imported chat!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid Gemini export format'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing JSON: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _exportChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
