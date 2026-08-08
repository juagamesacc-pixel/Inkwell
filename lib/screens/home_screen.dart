import 'dart:convert';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../services/formatter_service.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';
import '../utils/zip_handler.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/glass/glass_action_button.dart';
import '../widgets/glass/glass_bottom_nav.dart';
import '../widgets/glass/glass_button.dart';
import '../widgets/glass/glass_search_bar.dart';
import '../widgets/glass/animated_gradient_background.dart';
import 'editor_screen.dart';
import 'chat_viewer_screen.dart';
import 'graph_screen.dart';
import 'settings_screen.dart';

enum _SortMode { recent, oldest, title }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _NotesView(
              onImport: _importFile,
              onExportAll: _exportAll,
              onOpenNote: _openNote,
              onDeleteNote: _deleteNote,
            ),
            const GraphScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: GlassBottomNav(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            GlassNavItem(
              icon: Icons.edit_note_outlined,
              selectedIcon: Icons.edit_note_rounded,
              label: 'Notes',
            ),
            GlassNavItem(
              icon: Icons.graphic_eq_outlined,
              selectedIcon: Icons.graphic_eq_rounded,
              label: 'Graph',
            ),
            GlassNavItem(
              icon: Icons.tune_outlined,
              selectedIcon: Icons.tune_rounded,
              label: 'Settings',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? Padding(
                padding: const EdgeInsets.only(bottom: 88),
                child: GlassButton(
                  onPressed: _showCreateNoteSheet,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'New Note',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                )
            : null,
      ),
    );
  }

  // ---- Create note ----------------------------------------------------

  void _showCreateNoteSheet() {
    final titleController = TextEditingController();
    NoteType selectedType = NoteType.markdown;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassSheet(
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 8),
                Text(
                  'Create New Note',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick a format to get started',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter note title',
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: 'Markdown',
                        icon: Icons.edit_note_rounded,
                        color: AppColors.markdownAccent,
                        selected: selectedType == NoteType.markdown,
                        onTap: () =>
                            setModalState(() => selectedType = NoteType.markdown),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeChip(
                        label: 'Chat',
                        icon: Icons.chat_bubble_rounded,
                        color: AppColors.chatAccent,
                        selected: selectedType == NoteType.chat,
                        onTap: () =>
                            setModalState(() => selectedType = NoteType.chat),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a title'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    final storage = context.read<StorageService>();
                    final note = await storage.createNote(
                      title: title,
                      type: selectedType,
                    );
                    if (mounted) _openNote(note);
                  },
                  child: const Text(
                    'Create Note',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _importFile();
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Import from file instead'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- Import / export ------------------------------------------------

  Future<void> _importFile() async {
    if (_importing) return;
    setState(() => _importing = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'json', 'zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      final name = file.name;
      if (bytes == null) {
        _toast('Could not read file', error: true);
        return;
      }

      final storage = context.read<StorageService>();
      final text = utf8.decode(bytes, allowMalformed: true);

      if (name.toLowerCase().endsWith('.zip')) {
        final imported = await ZipHandler.importFromZip(bytes, storage);
        _toast('Imported ${imported.length} notes from zip');
      } else if (name.toLowerCase().endsWith('.md')) {
        await storage.importMarkdown(name, text);
        _toast('Imported "$name"');
      } else if (name.toLowerCase().endsWith('.json')) {
        final imported = await _importJson(name, text);
        _toast(imported == null ? 'Unrecognized JSON format' : 'Imported "$name"',
            error: imported == null);
      } else {
        _toast('Unsupported file type', error: true);
      }
    } catch (e) {
      _toast('Import failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<String?> _importJson(String name, String text) async {
    try {
      final json = jsonDecode(text);
      if (json is! Map) return null;
      final map = Map<String, dynamic>.from(json);
      final storage = context.read<StorageService>();
      if (FormatterService.isGeminiFormat(map)) {
        final note = await storage.importGeminiExport(name, text);
        return note.title;
      } else if (FormatterService.isValidChatFormat(map)) {
        final note = await storage.importChatJson(name, text);
        return note.title;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportAll() async {
    try {
      final storage = context.read<StorageService>();
      if (storage.notes.isEmpty) {
        _toast('No notes to export yet');
        return;
      }
      final file = await ZipHandler.exportNotesToZip(storage.notes, storage);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip')],
        text: 'Inkwell notes backup',
      );
    } catch (e) {
      _toast('Export failed: $e', error: true);
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

  // ---- Navigation -----------------------------------------------------

  void _openNote(Note note) {
    final route = PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        if (note.type == NoteType.markdown) {
          return EditorScreen(note: note);
        }
        return ChatViewerScreen(note: note);
      },
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
    Navigator.push(context, route);
  }

  void _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('"${note.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<StorageService>().deleteNote(note);
    }
  }
}

// ---- Notes view -----------------------------------------------------------

class _NotesView extends StatefulWidget {
  final VoidCallback onImport;
  final VoidCallback onExportAll;
  final ValueChanged<Note> onOpenNote;
  final ValueChanged<Note> onDeleteNote;

  const _NotesView({
    required this.onImport,
    required this.onExportAll,
    required this.onOpenNote,
    required this.onDeleteNote,
  });

  @override
  State<_NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<_NotesView> {
  String _query = '';
  NoteType? _filter;
  _SortMode _sort = _SortMode.recent;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _NotesHeader(
            noteCount: storage.notes.length,
            wordCount: storage.totalWordCount,
            linkCount: storage.totalLinks,
            onImport: widget.onImport,
            onExport: widget.onExportAll,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: GlassSearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _FilterBar(
            filter: _filter,
            sort: _sort,
            onFilterChanged: (f) => setState(() => _filter = f),
            onSortChanged: (s) => setState(() => _sort = s),
          ),
        ),
        _buildList(context, storage),
      ],
    );
  }

  Widget _buildList(BuildContext context, StorageService storage) {
    var results = storage.notes;
    if (_query.isNotEmpty) {
      results = storage.searchNotes(_query);
    }
    if (_filter != null) {
      results = results.where((n) => n.type == _filter).toList();
    }

    final filtered = List<Note>.from(results);
    switch (_sort) {
      case _SortMode.recent:
        filtered.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.modifiedAt.compareTo(a.modifiedAt);
        });
        break;
      case _SortMode.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortMode.title:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      sliver: filtered.isEmpty
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: _query.isEmpty && _filter == null
                  ? const EmptyState(
                      illustration: 'assets/svg/empty_notes.svg',
                      title: 'No notes yet',
                      subtitle:
                          'Tap the "New Note" button to create your first note.',
                    )
                  : EmptyState(
                      illustration: 'assets/svg/empty_notes.svg',
                      title: 'No results found',
                      subtitle: 'Try a different search term or filter.',
                    ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = filtered[index];
                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 14 : 0),
                    child: NoteCard(
                      note: note,
                      index: index,
                      onTap: () => widget.onOpenNote(note),
                      onDelete: () => widget.onDeleteNote(note),
                      onTogglePin: () =>
                          context.read<StorageService>().togglePin(note),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(
                            milliseconds: 40 * index.clamp(0, 8).toInt()),
                        duration: const Duration(milliseconds: 380),
                      ).slideY(
                        begin: 0.08,
                        end: 0,
                        delay: Duration(
                            milliseconds: 40 * index.clamp(0, 8).toInt()),
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOut,
                      );
                },
                childCount: filtered.length,
              ),
            ),
    );
  }
}

// ---- Header ---------------------------------------------------------------

class _NotesHeader extends StatelessWidget {
  final int noteCount;
  final int wordCount;
  final int linkCount;
  final VoidCallback onImport;
  final VoidCallback onExport;

  const _NotesHeader({
    required this.noteCount,
    required this.wordCount,
    required this.linkCount,
    required this.onImport,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 46, radius: 15),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inkwell',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Your second brain',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              GlassActionButton(
                icon: Icons.upload_file_rounded,
                tooltip: 'Import',
                color: colorScheme.primary,
                onPressed: onImport,
              ),
              const SizedBox(width: 8),
              GlassActionButton(
                icon: Icons.folder_zip_rounded,
                tooltip: 'Export all',
                color: colorScheme.tertiary,
                onPressed: onExport,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  label: 'Notes',
                  value: '$noteCount',
                  icon: Icons.edit_note_rounded,
                  gradient: AppColors.oceanGradient,
                  tint: AppColors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatsCard(
                  label: 'Words',
                  value: _compact(wordCount),
                  icon: Icons.text_fields_rounded,
                  gradient: AppColors.forestGradient,
                  tint: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatsCard(
                  label: 'Links',
                  value: '$linkCount',
                  icon: Icons.link_rounded,
                  gradient: AppColors.cosmicGradient,
                  tint: AppColors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }
}

// ---- Filter bar -----------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final NoteType? filter;
  final _SortMode sort;
  final ValueChanged<NoteType?> onFilterChanged;
  final ValueChanged<_SortMode> onSortChanged;

  const _FilterBar({
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = <(String, NoteType?)>[
      ('All', null),
      ('Markdown', NoteType.markdown),
      ('Chat', NoteType.chat),
      ('Imported', NoteType.googleDocs),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: chips.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == chips.length) {
              return _SortChip(sort: sort, onChanged: onSortChanged);
            }
            final (label, value) = chips[index];
            final selected = filter == value;
            return GestureDetector(
              onTap: () => onFilterChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.92),
                            colorScheme.primary.withOpacity(0.7),
                          ],
                        )
                      : null,
                  color: selected
                      ? null
                      : (isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white.withOpacity(0.6)),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : colorScheme.outline.withOpacity(0.6),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final _SortMode sort;
  final ValueChanged<_SortMode> onChanged;

  const _SortChip({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<_SortMode>(
      tooltip: 'Sort',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _SortMode.recent,
          child: Row(children: [
            Icon(Icons.schedule_rounded, size: 18),
            SizedBox(width: 10),
            Text('Recent'),
          ]),
        ),
        const PopupMenuItem(
          value: _SortMode.oldest,
          child: Row(children: [
            Icon(Icons.history_rounded, size: 18),
            SizedBox(width: 10),
            Text('Oldest'),
          ]),
        ),
        const PopupMenuItem(
          value: _SortMode.title,
          child: Row(children: [
            Icon(Icons.sort_by_alpha_rounded, size: 18),
            SizedBox(width: 10),
            Text('Title'),
          ]),
        ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.6),
          border: Border.all(color: colorScheme.outline.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(
              sort == _SortMode.recent
                  ? Icons.schedule_rounded
                  : sort == _SortMode.oldest
                      ? Icons.history_rounded
                      : Icons.sort_by_alpha_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              sort.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _SortModeX on _SortMode {
  String get label {
    switch (this) {
      case _SortMode.recent:
        return 'Recent';
      case _SortMode.oldest:
        return 'Oldest';
      case _SortMode.title:
        return 'Title';
    }
  }
}

// ---- Shared sheet pieces --------------------------------------------------

class _GlassSheet extends StatelessWidget {
  final Widget child;

  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF141A2A).withOpacity(0.96),
                        const Color(0xFF0C101C).withOpacity(0.98),
                      ]
                    : [
                        Colors.white.withOpacity(0.97),
                        const Color(0xFFF2F5FF).withOpacity(0.98),
                      ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.15),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.25), color.withOpacity(0.12)],
                )
              : null,
          color: selected
              ? null
              : Theme.of(context).colorScheme.surface.withOpacity(0.3),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.5)
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? color : Colors.grey.withOpacity(0.6),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
