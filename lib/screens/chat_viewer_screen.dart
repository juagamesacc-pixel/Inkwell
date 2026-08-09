import 'dart:convert';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../services/formatter_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/chat_markdown.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass/glass_action_button.dart';
import '../widgets/glass/glass_app_bar.dart';
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
  bool _showDownArrow = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(() {
      final atBottom = _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 120;
      if (atBottom != _showDownArrow) {
        setState(() => _showDownArrow = atBottom);
      }
    });
  }

  Future<void> _loadMessages() async {
    final storage = context.read<StorageService>();
    final messages = await storage.readChatMessages(widget.note);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
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

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: widget.note.title,
          subtitle: _isLoading ? 'Loading…' : '${_messages.length} messages',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            GlassActionButton(
              icon: Icons.upload_file_rounded,
              tooltip: 'Import Gemini export',
              color: Theme.of(context).colorScheme.primary,
              onPressed: _convertFromGemini,
            ),
            const SizedBox(width: 6),
            GlassActionButton(
              icon: Icons.download_rounded,
              tooltip: 'Export chat',
              color: Theme.of(context).colorScheme.tertiary,
              onPressed: _messages.isEmpty ? null : _exportChat,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildChatView(settings),
            Positioned(
              right: 16,
              bottom: 24,
              child: AnimatedScale(
                scale: _showDownArrow ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedOpacity(
                  opacity: _showDownArrow ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: GlassActionButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _scrollToBottom,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      illustration: 'assets/svg/empty_chat.svg',
      title: 'No messages yet',
      subtitle: 'Import a Gemini export to turn a conversation into beautiful cards.',
      action: GlassButton(
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(SettingsService settings) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageGroup(message, settings, index);
      },
    );
  }

  Widget _buildMessageGroup(
      ChatMessage message, SettingsService settings, int index) {
    final compact = settings.chatBubbleStyle == 'compact';
    final spacious = settings.chatBubbleStyle == 'spacious';
    final bottomPad = spacious ? 26.0 : compact ? 10.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MessageBubble(
            title: 'You',
            titleColor: Theme.of(context).colorScheme.primary,
            message: message.userMessage,
            showTimestamp: settings.showTimestamps,
            timestamp: message.timestamp,
            compact: compact,
            fontSize: settings.fontSize,
            fromRight: false,
            onCopy: () => _copyText(message.userMessage),
          ),
          if (settings.showThoughts && message.thoughts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.88,
                  ),
                  child: ThoughtBubble(thoughts: message.thoughts),
                ),
              ),
            ),
          if (message.modelResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _MessageBubble(
                title: 'Model',
                titleColor: const Color(0xFF10B981),
                message: message.modelResponse,
                showTimestamp: settings.showTimestamps,
                timestamp: message.timestamp,
                compact: compact,
                fontSize: settings.fontSize,
                fromRight: true,
                onCopy: () => _copyText(message.modelResponse),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copyText(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ---- Import -----------------------------------------------------------

  void _convertFromGemini() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _importSheet(context),
    );
  }

  Widget _importSheet(BuildContext context) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.94),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Import conversation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a Gemini export file, or paste its JSON below.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 20),
                GlassButton(
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pop(context);
                    _pickGeminiFile();
                  },
                  child: const Text(
                    'Choose file',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR PASTE JSON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: colorScheme.surface.withValues(alpha: 0.6),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style:
                        const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '{ "chunkedPrompt": { "chunks": [...] } }',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          _processGeminiImport(controller.text);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Convert'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickGeminiFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;
    _processGeminiImport(utf8.decode(bytes, allowMalformed: true));
  }

  void _processGeminiImport(String jsonText) {
    try {
      final json = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);

      if (FormatterService.isGeminiFormat(json)) {
        final chatJson = FormatterService.convertGeminiToChat(json);
        final messages = FormatterService.parseChatJson(chatJson);

        setState(() => _messages = messages);
        context.read<StorageService>().saveChatMessages(widget.note, messages);
        _toast('Imported ${messages.length} messages');
        _scrollToBottom();
      } else if (FormatterService.isValidChatFormat(json)) {
        final messages = FormatterService.parseChatJson(json);
        setState(() => _messages = messages);
        context.read<StorageService>().saveChatMessages(widget.note, messages);
        _toast('Imported ${messages.length} messages');
        _scrollToBottom();
      } else {
        _toast('Unrecognized JSON format', error: true);
      }
    } catch (e) {
      _toast('Error parsing JSON: $e', error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- Export -----------------------------------------------------------

  Future<void> _exportChat() async {
    try {
      final storage = context.read<StorageService>();
      final file = await storage.exportChatToFile(widget.note);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        text: 'Inkwell chat export',
      );
    } catch (e) {
      _toast('Export failed: $e', error: true);
    }
  }
}

// ---- Message bubble ---------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final String title;
  final Color titleColor;
  final String message;
  final bool showTimestamp;
  final DateTime timestamp;
  final bool compact;
  final double fontSize;
  final bool fromRight;
  final VoidCallback? onCopy;

  const _MessageBubble({
    required this.title,
    required this.titleColor,
    required this.message,
    required this.showTimestamp,
    required this.timestamp,
    required this.compact,
    required this.fontSize,
    required this.fromRight,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: fromRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
        ),
        padding: EdgeInsets.all(compact ? 14 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(fromRight ? 20 : 6),
            bottomRight: Radius.circular(fromRight ? 6 : 20),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: fromRight
                ? [
                    const Color(0xFF10B981).withValues(alpha: 0.16),
                    const Color(0xFF14B8A6).withValues(alpha: 0.08),
                  ]
                : [
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.primary.withValues(alpha: 0.08),
                  ],
          ),
          border: Border.all(
            color: fromRight
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : colorScheme.primary.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 11 : 12.5,
                    color: titleColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                if (showTimestamp)
                  Text(
                    DateFormat('h:mm a').format(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                const Spacer(),
                if (onCopy != null)
                  GestureDetector(
                    onTap: onCopy,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ChatMarkdownBody(data: message, fontSize: fontSize),
          ],
        ),
      ),
    );
  }
}
