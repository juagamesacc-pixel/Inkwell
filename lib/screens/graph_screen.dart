import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/link_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass/glass_action_button.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_card.dart';
import 'editor_screen.dart';
import 'chat_viewer_screen.dart';
import '../widgets/graph_painter.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, List<String>> _graph = {};
  List<Note> _notes = [];
  String? _selectedNoteId;
  Map<String, Offset> _nodePositions = {};
  String _lastLayout = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _buildGraph() {
    final storage = context.read<StorageService>();
    _notes = storage.notes;
    _graph = LinkService.buildLinkGraph(_notes);
    _layoutNodes();
    if (mounted) setState(() {});
  }

  /// Lightweight sync used during build (no setState).
  void _syncFrom(StorageService storage, String layout) {
    if (_notes.length != storage.notes.length) {
      _notes = storage.notes;
      _graph = LinkService.buildLinkGraph(_notes);
      _selectedNoteId = null;
    }
    if (_lastLayout != layout) {
      _lastLayout = layout;
      _layoutNodes();
    }
  }

  void _layoutNodes() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);

    _nodePositions.clear();
    switch (_lastLayout) {
      case 'circular':
        _layoutCircular(center, size);
        break;
      case 'tree':
        _layoutTree(center, size);
        break;
      default:
        _layoutForceDirected(center, Random(42));
    }
  }

  void _layoutCircular(Offset center, Size size) {
    final radius = min(size.width, size.height) / 2.6;
    for (var i = 0; i < _notes.length; i++) {
      final angle = (2 * pi * i) / _notes.length - pi / 2;
      _nodePositions[_notes[i].id] = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }
  }

  void _layoutTree(Offset center, Size size) {
    final levels = <String, int>{};
    final visited = <String>{};

    void dfs(String nodeId, int level) {
      if (visited.contains(nodeId)) return;
      visited.add(nodeId);
      levels[nodeId] = level;
      for (final childId in _graph[nodeId] ?? []) {
        dfs(childId, level + 1);
      }
    }

    final hasIncoming = _graph.values.expand((e) => e).toSet();
    for (final note in _notes) {
      if (!hasIncoming.contains(note.id)) {
        dfs(note.id, 0);
      }
    }
    for (final note in _notes) {
      if (!levels.containsKey(note.id)) dfs(note.id, 0);
    }

    final byLevel = <int, List<String>>{};
    levels.forEach((nodeId, level) {
      byLevel.putIfAbsent(level, () => []).add(nodeId);
    });

    final maxLevel = byLevel.keys.isEmpty ? 0 : byLevel.keys.reduce(max);
    final levelHeight = size.height / (maxLevel + 2.5);

    byLevel.forEach((level, nodeIds) {
      final levelWidth = size.width / (nodeIds.length + 1);
      for (var i = 0; i < nodeIds.length; i++) {
        _nodePositions[nodeIds[i]] = Offset(
          levelWidth * (i + 1),
          levelHeight * (level + 1.2),
        );
      }
    });
  }

  void _layoutForceDirected(Offset center, Random random) {
    for (final note in _notes) {
      _nodePositions[note.id] = Offset(
        center.dx + (random.nextDouble() - 0.5) * 280,
        center.dy + (random.nextDouble() - 0.5) * 280,
      );
    }

    for (var iteration = 0; iteration < 60; iteration++) {
      final forces = <String, Offset>{
        for (final note in _notes) note.id: Offset.zero,
      };

      for (var i = 0; i < _notes.length; i++) {
        for (var j = i + 1; j < _notes.length; j++) {
          final pos1 = _nodePositions[_notes[i].id]!;
          final pos2 = _nodePositions[_notes[j].id]!;
          final diff = pos1 - pos2;
          final distance = diff.distance.clamp(1.0, double.infinity).toDouble();
          final force = 6000 / (distance * distance);
          final direction = diff / distance;

          forces[_notes[i].id] = forces[_notes[i].id]! + direction * force;
          forces[_notes[j].id] = forces[_notes[j].id]! - direction * force;
        }
      }

      for (final entry in _graph.entries) {
        final sourcePos = _nodePositions[entry.key];
        if (sourcePos == null) continue;
        for (final targetId in entry.value) {
          final targetPos = _nodePositions[targetId];
          if (targetPos == null) continue;
          final diff = targetPos - sourcePos;
          final distance = diff.distance.clamp(1.0, double.infinity).toDouble();
          final force = (distance - 120) * 0.012;
          final direction = diff / distance;
          forces[entry.key] = forces[entry.key]! + direction * force;
          forces[targetId] = forces[targetId]! - direction * force;
        }
      }

      for (final note in _notes) {
        final force = forces[note.id]!;
        _nodePositions[note.id] = _nodePositions[note.id]! + force * 0.1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final storage = context.watch<StorageService>();

    _syncFrom(storage, settings.graphLayout);

    final connectionCount = _graph.values.fold<int>(
        0, (sum, targets) => sum + targets.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Knowledge Graph',
        subtitle: '${_notes.length} notes · $connectionCount connections',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Layout',
            initialValue: settings.graphLayout,
            onSelected: (layout) {
              context.read<SettingsService>().setGraphLayout(layout);
              _lastLayout = layout;
              _buildGraph();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'force',
                child: Row(children: [
                  Icon(Icons.bubble_chart_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('Force Directed'),
                ]),
              ),
              PopupMenuItem(
                value: 'circular',
                child: Row(children: [
                  Icon(Icons.circle_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('Circular'),
                ]),
              ),
              PopupMenuItem(
                value: 'tree',
                child: Row(children: [
                  Icon(Icons.account_tree_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('Tree'),
                ]),
              ),
            ],
            child: const GlassActionButton(
              icon: Icons.layers_rounded,
              color: AppColors.violet,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (_notes.isEmpty)
            const EmptyState(
              illustration: 'assets/svg/empty_graph.svg',
              title: 'No graph yet',
              subtitle:
                  'Create notes with [[wiki links]] to see your knowledge grow.',
            )
          else
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(120),
                  minScale: 0.2,
                  maxScale: 3.5,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: CustomPaint(
                      painter: GraphPainter(
                        notes: _notes,
                        graph: _graph,
                        nodePositions: _nodePositions,
                        selectedNoteId: _selectedNoteId,
                        animationValue: _controller.value,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (details) =>
                            _handleTap(details.localPosition),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_notes.isNotEmpty) _buildLegend(context),
          if (_selectedNoteId != null)
            _buildSelectedCard(context, _selectedNoteId!),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 96,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            _legendDot(context, AppColors.markdownAccent, 'Notes'),
            const SizedBox(width: 14),
            _legendDot(context, AppColors.chatAccent, 'Chat'),
            const SizedBox(width: 14),
            _legendDot(context, AppColors.importedAccent, 'Imported'),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCard(BuildContext context, String noteId) {
    final note = _notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => _notes.first,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 96,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.25),
                    colorScheme.primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                note.type == NoteType.markdown
                    ? Icons.edit_note_rounded
                    : note.type == NoteType.chat
                        ? Icons.chat_bubble_rounded
                        : Icons.article_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${note.wordCount} words · ${note.type.label}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            GlassActionButton(
              icon: Icons.open_in_new_rounded,
              color: colorScheme.primary,
              onPressed: () {
                _openNote(note);
              },
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() => _selectedNoteId = null),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    for (final note in _notes) {
      final nodePos = _nodePositions[note.id];
      if (nodePos == null) continue;
      if ((position - nodePos).distance < 34) {
        setState(() {
          _selectedNoteId = _selectedNoteId == note.id ? null : note.id;
        });
        return;
      }
    }
    setState(() => _selectedNoteId = null);
  }

  void _openNote(Note note) {
    final route = MaterialPageRoute(
      builder: (context) => note.type == NoteType.markdown
          ? EditorScreen(note: note)
          : ChatViewerScreen(note: note),
    );
    Navigator.push(context, route);
  }
}
