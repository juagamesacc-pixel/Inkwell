import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import '../widgets/animated_search_bar.dart';
import 'editor_screen.dart';
import 'chat_viewer_screen.dart';
import 'graph_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildNotesView(),
          const GraphScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_outlined),
            selectedIcon: Icon(Icons.graphic_eq),
            label: 'Graph',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? _buildFAB()
          : null,
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreateNoteDialog,
      icon: const Icon(Icons.add),
      label: const Text('New Note'),
    ).animate().scale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildNotesView() {
    return Consumer<StorageService>(
      builder: (context, storage, child) {
        final notes = _searchQuery.isEmpty
            ? storage.notes
            : storage.searchNotes(_searchQuery);

        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text(
                'Inkwell',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildSearchSheet(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _importFile,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: notes.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = notes[index];
                          return NoteCard(
                            note: note,
                            onTap: () => _openNote(note),
                            onDelete: () => _deleteNote(note),
                          ).animate().fadeIn(
                            duration: Duration(milliseconds: 300 * context.read<SettingsService>().animationSpeed.toInt()),
                            delay: Duration(milliseconds: 50 * index),
                          );
                        },
                        childCount: notes.length,
                      ),
                    ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
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
          Icon(
            Icons.note_add_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first note',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedSearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              Expanded(
                child: Consumer<StorageService>(
                  builder: (context, storage, child) {
                    final results = _searchQuery.isEmpty
                        ? storage.notes
                        : storage.searchNotes(_searchQuery);
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final note = results[index];
                        return ListTile(
                          leading: Icon(
                            note.type == NoteType.chat
                                ? Icons.chat_bubble_outline
                                : note.type == NoteType.googleDocs
                                    ? Icons.article_outlined
                                    : Icons.note_outlined,
                          ),
                          title: Text(note.title),
                          subtitle: Text(
                            note.content.substring(0, 
                              note.content.length.clamp(0, 50)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _openNote(note);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create New',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter note title',
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<NoteType>(
                  segments: const [
                    ButtonSegment(
                      value: NoteType.markdown,
                      label: Text('Markdown'),
                      icon: Icon(Icons.note_outlined),
                    ),
                    ButtonSegment(
                      value: NoteType.chat,
                      label: Text('Chat'),
                      icon: Icon(Icons.chat_bubble_outlined),
                    ),
                    ButtonSegment(
                      value: NoteType.googleDocs,
                      label: Text('Import'),
                      icon: Icon(Icons.upload_file_outlined),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selection) {
                    setModalState(() => selectedType = selection.first);
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
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
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
      },
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

  void _importFile() async {
    // Show import dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              // TODO: Implement file picker
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }
}
