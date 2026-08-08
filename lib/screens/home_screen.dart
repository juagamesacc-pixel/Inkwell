import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_bottom_nav.dart';
import '../widgets/glass/glass_search_bar.dart';
import '../widgets/glass/glass_button.dart';
import '../widgets/glass/animated_gradient_background.dart';
import 'editor_screen.dart';
import 'chat_viewer_screen.dart';
import 'graph_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildNotesView(),
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
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: 'Settings',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? _buildFAB()
            : null,
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: GlassButton(
        onPressed: _showCreateNoteDialog,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'New Note',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ).animate().scale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _buildNotesView() {
    return Consumer<StorageService>(
      builder: (context, storage, child) {
        final notes = _searchQuery.isEmpty
            ? storage.notes
            : storage.searchNotes(_searchQuery);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inkwell',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideX(
                              begin: -0.1,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOut,
                            ),
                        const SizedBox(height: 4),
                        Text(
                          '${notes.length} notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                    const Spacer(),
                    // Import button
                    IconButton(
                      onPressed: _importFile,
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.upload_file_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ).animate().fadeIn(delay: 150.ms).scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          delay: 150.ms,
                          duration: 300.ms,
                        ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: GlassSearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ).animate().fadeIn(delay: 250.ms).slideY(
                      begin: 0.1,
                      end: 0,
                      delay: 250.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),

            // Notes list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              sliver: notes.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = notes[index];
                          return NoteCard(
                            note: note,
                            index: index,
                            onTap: () => _openNote(note),
                            onDelete: () => _deleteNote(note),
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: 50 * index),
                                duration: const Duration(milliseconds: 400),
                              ).slideY(
                                begin: 0.15,
                                end: 0,
                                delay: Duration(milliseconds: 50 * index),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                        },
                        childCount: notes.length,
                      ),
                    ),
            ),
          ],
        );
      },
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
              Icons.note_add_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
          ).animate().scale(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first note',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.3),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  void _showCreateNoteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateNoteSheet(),
    );
  }

  Widget _buildCreateNoteSheet() {
    final titleController = TextEditingController();
    NoteType selectedType = NoteType.markdown;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Create New',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title input
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: TextField(
                          controller: titleController,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter note title',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Type selector
                    Row(
                      children: [
                        _buildTypeChip(
                          context,
                          'Markdown',
                          Icons.edit_note_rounded,
                          NoteType.markdown,
                          selectedType,
                          (type) => setModalState(() => selectedType = type),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          context,
                          'Chat',
                          Icons.chat_bubble_rounded,
                          NoteType.chat,
                          selectedType,
                          (type) => setModalState(() => selectedType = type),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(
                          context,
                          'Import',
                          Icons.upload_file_rounded,
                          NoteType.googleDocs,
                          selectedType,
                          (type) => setModalState(() => selectedType = type),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    GlassButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          Navigator.pop(context);
                          final storage = context.read<StorageService>();
                          final note = await storage.createNote(
                            title: titleController.text,
                            type: selectedType,
                          );
                          _openNote(note);
                        }
                      },
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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

  Widget _buildTypeChip(
    BuildContext context,
    String label,
    IconData icon,
    NoteType type,
    NoteType selected,
    ValueChanged<NoteType> onSelected,
  ) {
    final isSelected = type == selected;
    final color = type == NoteType.markdown
        ? const Color(0xFF6366F1)
        : type == NoteType.chat
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  )
                : null,
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? color
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNote(Note note) {
    switch (note.type) {
      case NoteType.markdown:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EditorScreen(note: note),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
        break;
      case NoteType.chat:
      case NoteType.googleDocs:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChatViewerScreen(note: note),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
        break;
    }
  }

  void _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"?'),
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

  void _importFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Import File'),
        content: const Text('Import a Gemini export or chat JSON file'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }
}
