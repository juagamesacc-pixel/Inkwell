import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/link_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_markdown_builder.dart';
import '../widgets/glass/glass_action_button.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/animated_gradient_background.dart';

enum _EditorMode { edit, split, preview }

class EditorScreen extends StatefulWidget {
  final Note note;

  const EditorScreen({super.key, required this.note});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note _currentNote;
  late _EditorMode _mode;
  late final StorageService _storage;

  Timer? _saveDebounce;
  bool _hasChanges = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _storage = context.read<StorageService>();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);

    final settings = context.read<SettingsService>();
    _mode = switch (settings.editorMode) {
      'preview' => _EditorMode.preview,
      'split' => _EditorMode.split,
      _ => _EditorMode.edit,
    };

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _saveNow();
    });
  }

  Future<void> _persist() async {
    if (!_hasChanges) return;
    final tags = LinkService.extractTags(_contentController.text);
    await _storage.updateNote(
      _currentNote,
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      content: _contentController.text,
      tags: tags,
    );
  }

  Future<void> _saveNow({bool force = false}) async {
    if (!_hasChanges && !force) return;
    setState(() {
      _saving = true;
      _hasChanges = false;
    });
    final tags = LinkService.extractTags(_contentController.text);
    await _storage.updateNote(
      _currentNote,
      title: _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      content: _contentController.text,
      tags: tags,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _persist();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsService>();
    final words = _contentController.text.trim().isEmpty
        ? 0
        : _contentController.text.trim().split(RegExp(r'\s+')).length;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: '',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _saveAndPop,
          ),
          actions: [
            _statusPill(words),
            GlassActionButton(
              icon: Icons.link_rounded,
              tooltip: 'Links & backlinks',
              onPressed: _showLinks,
            ),
            const SizedBox(width: 4),
            _ModeSwitch(
              mode: _mode,
              onChanged: (mode) {
                setState(() => _mode = mode);
                settings.setEditorMode(mode == _EditorMode.edit
                    ? 'live'
                    : mode == _EditorMode.split
                        ? 'split'
                        : 'preview');
              },
            ),
            const SizedBox(width: 8),
          ],
          titleWidget: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Note title',
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                  fontWeight: FontWeight.w600,
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        body: switch (_mode) {
          _EditorMode.edit => _buildEditorPane(context, settings),
          _EditorMode.split => Row(
              children: [
                Expanded(child: _buildEditorPane(context, settings)),
                Container(
                  width: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(0.4),
                ),
                Expanded(child: _buildPreviewPane(context)),
              ],
            ),
          _EditorMode.preview => _buildPreviewPane(context),
        },
      ),
    );
  }

  Widget _statusPill(int words) {
    final colorScheme = Theme.of(context).colorScheme;
    final minutes = (words / 200).ceil();

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: colorScheme.surface.withOpacity(0.5),
          border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_saving)
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: colorScheme.primary,
                ),
              )
            else
              Icon(
                _hasChanges
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_done_outlined,
                size: 14,
                color: _hasChanges
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
            const SizedBox(width: 6),
            Text(
              '$words words',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '  ·  $minutes min',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Editor pane -----------------------------------------------------

  Widget _buildEditorPane(BuildContext context, SettingsService settings) {
    return Column(
      children: [
        _MarkdownToolbar(controller: _contentController),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _GlassEditorContainer(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: settings.fontSize,
                  fontFamily: settings.fontFamily,
                  height: 1.75,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing…\n\n'
                      '  •  [[Link]] to another note\n'
                      '  •  #tag your ideas\n'
                      '  •  Use markdown for structure',
                  border: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.25),
                    height: 1.75,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Preview pane -----------------------------------------------------

  Widget _buildPreviewPane(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled'
        : _titleController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _tagChip(context, Icons.schedule_rounded,
                  DateFormat('MMM d, yyyy').format(DateTime.now())),
              const SizedBox(width: 8),
              _tagChip(context, Icons.edit_note_rounded,
                  '${_currentNote.wordCount} words'),
            ],
          ),
          if (LinkService.extractTags(_contentController.text).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    LinkService.extractTags(_contentController.text).map((t) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.18),
                          colorScheme.primary.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 18),
          _GlassEditorContainer(
            child: CustomMarkdownBuilder(
              data: _contentController.text,
              onLinkTap: _handleLinkTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: colorScheme.surface.withOpacity(0.5),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurface.withOpacity(0.45)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Link navigation -------------------------------------------------

  void _handleLinkTap(String target) {
    if (target.isEmpty) return;
    final storage = context.read<StorageService>();
    final match = storage.notes.where((n) =>
        n.title.toLowerCase() == target.toLowerCase() ||
        n.title.toLowerCase().contains(target.toLowerCase()));
    if (match.isNotEmpty && match.first.id != _currentNote.id) {
      _saveNow();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditorScreen(note: match.first)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No note named "$target"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ---- Links sheet ------------------------------------------------------

  void _showLinks() {
    final links = LinkService.extractLinks(_contentController.text);
    final backlinks = LinkService.getBacklinks(
      _currentNote,
      context.read<StorageService>().notes,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.92),
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
                          color: colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connections',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${links.length} outgoing · ${backlinks.length} backlinks',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (links.isNotEmpty) ...[
                              _sectionLabel(context, 'OUTGOING LINKS'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: links.map((link) {
                                  final exists = context
                                      .read<StorageService>()
                                      .notes
                                      .any((n) =>
                                          n.title.toLowerCase() ==
                                          link.toLowerCase());
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _handleLinkTap(link);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          colors: exists
                                              ? [
                                                  colorScheme.primary
                                                      .withOpacity(0.2),
                                                  colorScheme.primary
                                                      .withOpacity(0.1),
                                                ]
                                              : [
                                                  colorScheme.outline
                                                      .withOpacity(0.5),
                                                  colorScheme.outline
                                                      .withOpacity(0.3),
                                                ],
                                        ),
                                        border: Border.all(
                                          color: exists
                                              ? colorScheme.primary
                                                  .withOpacity(0.3)
                                              : colorScheme.outline
                                                  .withOpacity(0.6),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            exists
                                                ? Icons.link_rounded
                                                : Icons.link_off_rounded,
                                            size: 14,
                                            color: exists
                                                ? colorScheme.primary
                                                : colorScheme.onSurface
                                                    .withOpacity(0.4),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            link,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: exists
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurface
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (backlinks.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _sectionLabel(context, 'BACKLINKS'),
                              const SizedBox(height: 8),
                              ...backlinks.map((note) {
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: colorScheme.primary
                                          .withOpacity(0.1),
                                    ),
                                    child: const Icon(Icons.north_east_rounded,
                                        size: 16),
                                  ),
                                  title: Text(
                                    note.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (note.id != _currentNote.id) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditorScreen(note: note),
                                        ),
                                      );
                                    }
                                  },
                                );
                              }),
                            ],
                            if (links.isEmpty && backlinks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No connections yet.\nUse [[Note Title]] to link notes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: colorScheme.onSurface.withOpacity(0.35),
      ),
    );
  }

  void _saveAndPop() async {
    _saveDebounce?.cancel();
    await _saveNow(force: true);
    if (mounted) Navigator.pop(context);
  }
}

// ---- Glass editor container ----------------------------------------------

class _GlassEditorContainer extends StatelessWidget {
  final Widget child;

  const _GlassEditorContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.92),
                      Colors.white.withOpacity(0.75),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---- Mode switch ------------------------------------------------------------

class _ModeSwitch extends StatelessWidget {
  final _EditorMode mode;
  final ValueChanged<_EditorMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    final items = <(_EditorMode, IconData, String)>[
      (_EditorMode.edit, Icons.edit_rounded, 'Edit'),
      (_EditorMode.split, Icons.vertical_split_rounded, 'Split'),
      (_EditorMode.preview, Icons.visibility_rounded, 'Preview'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (m, icon, tip) = item;
          final selected = mode == m;
          return GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          accent.withOpacity(0.85),
                          accent.withOpacity(0.6),
                        ],
                      )
                    : null,
              ),
              child: Tooltip(
                message: tip,
                child: Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---- Markdown toolbar ---------------------------------------------------------

class _MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;

  const _MarkdownToolbar({required this.controller});

  static const _items = <(IconData, String, String, String, String)>[
    (Icons.format_bold_rounded, 'Bold', '**', '**', ''),
    (Icons.format_italic_rounded, 'Italic', '*', '*', ''),
    (Icons.title_rounded, 'Heading', '## ', '', ''),
    (Icons.format_list_bulleted_rounded, 'List', '- ', '', ''),
    (Icons.format_quote_rounded, 'Quote', '> ', '', ''),
    (Icons.code_rounded, 'Code', '`', '`', ''),
    (Icons.link_rounded, 'Link', '[', '](https://)', ''),
    (Icons.tag_rounded, 'Wiki link', '[[', ']]', ''),
    (Icons.remove_rounded, 'Divider', '\n---\n', '', ''),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _items.map((item) {
            final (icon, tip, prefix, suffix, _) = item;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tooltip(
                message: tip,
                child: InkWell(
                  onTap: () => _apply(prefix, suffix),
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      size: 17,
                      color: colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _apply(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final offset = selection.isValid ? selection.start : text.length;
      final before = text.substring(0, offset);
      final after = text.substring(offset);
      final selected = prefix == '## ' ? 'Heading' : 'text';
      controller.text = '$before$prefix$selected$suffix$after';
      final newOffset = (before + prefix + selected + suffix).length;
      controller.selection =
          TextSelection.collapsed(offset: newOffset);
      return;
    }

    final before = text.substring(0, selection.start);
    final selectedText = text.substring(selection.start, selection.end);
    final after = text.substring(selection.end);

    controller.text =
        '$before$prefix$selectedText$suffix$after';
    controller.selection = TextSelection(
      baseOffset: (before + prefix).length,
      extentOffset: (before + prefix + selectedText).length,
    );
  }
}
