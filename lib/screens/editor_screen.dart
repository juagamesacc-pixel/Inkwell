import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../services/link_service.dart';
import '../services/settings_service.dart';
import '../widgets/custom_markdown_builder.dart';

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
  bool _isEditing = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => _saveAndPop(),
        ),
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Title',
                ),
              )
            : Text(_titleController.text),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showLinks,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export'),
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
      body: _isEditing ? _buildEditor() : _buildPreview(),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: context.read<SettingsService>().fontSize,
                fontFamily: context.read<SettingsService>().fontFamily,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing...\n\nUse [[Note Title]] to link notes\nUse #tag to add tags',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _currentNote.tags.map((tag) {
              return Chip(
                label: Text(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const Divider(height: 32),
          CustomMarkdownBuilder(
            data: _contentController.text,
          ),
        ],
      ),
    );
  }

  void _showLinks() {
    final links = LinkService.extractLinks(_contentController.text);
    final backlinks = LinkService.getBacklinks(
      _currentNote,
      context.read<StorageService>().notes,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Links',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (links.isEmpty)
                const Text('No outgoing links')
              else ...[
                Text(
                  'Outgoing',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Wrap(
                  spacing: 8,
                  children: links.map((link) {
                    return ActionChip(
                      label: Text(link),
                      onPressed: () {
                        // Navigate to linked note
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (backlinks.isEmpty)
                const Text('No backlinks')
              else ...[
                Text(
                  'Backlinks',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ...backlinks.map((note) {
                  return ListTile(
                    title: Text(note.title),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to backlinked note
                    },
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  void _saveAndPop() async {
    if (_hasChanges) {
      final storage = context.read<StorageService>();
      await storage.updateNote(
        _currentNote,
        title: _titleController.text,
        content: _contentController.text,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
