import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../services/link_service.dart';
import '../services/settings_service.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _buildGraph();
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
    setState(() {});
  }

  void _layoutNodes() {
    final settings = context.read<SettingsService>();
    final random = Random(42);
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    _nodePositions.clear();

    switch (settings.graphLayout) {
      case 'circular':
        _layoutCircular(center);
        break;
      case 'tree':
        _layoutTree(center);
        break;
      case 'force':
      default:
        _layoutForceDirected(center, random);
    }
  }

  void _layoutCircular(Offset center) {
    final radius = min(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    ) / 3;

    for (var i = 0; i < _notes.length; i++) {
      final angle = (2 * pi * i) / _notes.length;
      _nodePositions[_notes[i].id] = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }
  }

  void _layoutTree(Offset center) {
    final Map<String, int> levels = {};
    final Set<String> visited = {};

    void dfs(String nodeId, int level) {
      if (visited.contains(nodeId)) return;
      visited.add(nodeId);
      levels[nodeId] = level;
      
      for (var childId in _graph[nodeId] ?? []) {
        dfs(childId, level + 1);
      }
    }

    final hasIncoming = _graph.values.expand((e) => e).toSet();
    for (var note in _notes) {
      if (!hasIncoming.contains(note.id)) {
        dfs(note.id, 0);
      }
    }

    final byLevel = <int, List<String>>{};
    levels.forEach((nodeId, level) {
      byLevel.putIfAbsent(level, () => []).add(nodeId);
    });

    final maxLevel = byLevel.keys.isEmpty ? 0 : byLevel.keys.reduce(max);
    final levelHeight = MediaQuery.of(context).size.height / (maxLevel + 2);

    byLevel.forEach((level, nodeIds) {
      final levelWidth = MediaQuery.of(context).size.width / (nodeIds.length + 1);
      for (var i = 0; i < nodeIds.length; i++) {
        _nodePositions[nodeIds[i]] = Offset(
          levelWidth * (i + 1),
          levelHeight * (level + 1),
        );
      }
    });
  }

  void _layoutForceDirected(Offset center, Random random) {
    for (var note in _notes) {
      _nodePositions[note.id] = Offset(
        center.dx + (random.nextDouble() - 0.5) * 300,
        center.dy + (random.nextDouble() - 0.5) * 300,
      );
    }

    for (var iteration = 0; iteration < 50; iteration++) {
      final forces = <String, Offset>{};

      for (var note in _notes) {
        forces[note.id] = Offset.zero;
      }

      for (var i = 0; i < _notes.length; i++) {
        for (var j = i + 1; j < _notes.length; j++) {
          final pos1 = _nodePositions[_notes[i].id]!;
          final pos2 = _nodePositions[_notes[j].id]!;
          final diff = pos1 - pos2;
          final distance = diff.distance.clamp(1.0, double.infinity);
          final force = 5000 / (distance * distance);
          final direction = diff / distance;

          forces[_notes[i].id] = forces[_notes[i].id]! + direction * force;
          forces[_notes[j].id] = forces[_notes[j].id]! - direction * force;
        }
      }

      for (var entry in _graph.entries) {
        final sourcePos = _nodePositions[entry.key];
        if (sourcePos == null) continue;

        for (var targetId in entry.value) {
          final targetPos = _nodePositions[targetId];
          if (targetPos == null) continue;

          final diff = targetPos - sourcePos;
          final distance = diff.distance.clamp(1.0, double.infinity);
          final force = (distance - 100) * 0.01;
          final direction = diff / distance;

          forces[entry.key] = forces[entry.key]! + direction * force;
          forces[targetId] = forces[targetId]! - direction * force;
        }
      }

      for (var note in _notes) {
        final force = forces[note.id]!;
        _nodePositions[note.id] = _nodePositions[note.id]! + force * 0.1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Knowledge Graph',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'force',
                child: Text('Force Directed'),
              ),
              const PopupMenuItem(
                value: 'circular',
                child: Text('Circular'),
              ),
              const PopupMenuItem(
                value: 'tree',
                child: Text('Tree'),
              ),
            ],
            onSelected: (layout) {
              context.read<SettingsService>().setGraphLayout(layout);
              _buildGraph();
            },
          ),
        ],
      ),
      body: _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes to display',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: CustomPaint(
                    painter: GraphPainter(
                      notes: _notes,
                      graph: _graph,
                      nodePositions: _nodePositions,
                      selectedNoteId: _selectedNoteId,
                      animationValue: _controller.value,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                    child: GestureDetector(
                      onTapUp: (details) {
                        _handleTap(details.localPosition);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _handleTap(Offset position) {
    for (var note in _notes) {
      final nodePos = _nodePositions[note.id];
      if (nodePos != null) {
        final distance = (position - nodePos).distance;
        if (distance < 30) {
          setState(() {
            _selectedNoteId = _selectedNoteId == note.id ? null : note.id;
          });
          return;
        }
      }
    }
  }
}
