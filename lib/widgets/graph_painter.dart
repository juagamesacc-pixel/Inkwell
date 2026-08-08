import 'dart:math';
import 'package:flutter/material.dart';
import '../models/note.dart';

class GraphPainter extends CustomPainter {
  final List<Note> notes;
  final Map<String, List<String>> graph;
  final Map<String, Offset> nodePositions;
  final String? selectedNoteId;
  final double animationValue;
  final ColorScheme colorScheme;

  GraphPainter({
    required this.notes,
    required this.graph,
    required this.nodePositions,
    this.selectedNoteId,
    required this.animationValue,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    final edgePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final selectedEdgePaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (var entry in graph.entries) {
      final sourcePos = nodePositions[entry.key];
      if (sourcePos == null) continue;

      for (var targetId in entry.value) {
        final targetPos = nodePositions[targetId];
        if (targetPos == null) continue;

        final isSelected = selectedNoteId == entry.key || 
                          selectedNoteId == targetId;

        final path = Path();
        path.moveTo(sourcePos.dx, sourcePos.dy);

        final controlPoint = Offset(
          (sourcePos.dx + targetPos.dx) / 2,
          (sourcePos.dy + targetPos.dy) / 2 - 50,
        );

        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          targetPos.dx,
          targetPos.dy,
        );

        canvas.drawPath(
          path,
          isSelected ? selectedEdgePaint : edgePaint,
        );

        _drawArrow(canvas, targetPos, sourcePos, isSelected ? selectedEdgePaint : edgePaint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset target, Offset source, Paint paint) {
    final direction = (source - target);
    final distance = direction.distance;
    if (distance == 0) return;

    final normalized = direction / distance;
    const arrowSize = 8.0;

    final arrowPoint = target + normalized * 30;
    final leftArrow = arrowPoint + Offset(
      -normalized.dy * arrowSize / 2 + normalized.dx * arrowSize / 2,
      normalized.dx * arrowSize / 2 + normalized.dy * arrowSize / 2,
    );
    final rightArrow = arrowPoint + Offset(
      normalized.dy * arrowSize / 2 + normalized.dx * arrowSize / 2,
      -normalized.dx * arrowSize / 2 + normalized.dy * arrowSize / 2,
    );

    final arrowPath = Path()
      ..moveTo(arrowPoint.dx, arrowPoint.dy)
      ..lineTo(leftArrow.dx, leftArrow.dy)
      ..lineTo(rightArrow.dx, rightArrow.dy)
      ..close();

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawNodes(Canvas canvas) {
    for (var note in notes) {
      final position = nodePositions[note.id];
      if (position == null) continue;

      final isSelected = selectedNoteId == note.id;
      final radius = isSelected ? 28.0 : 22.0;

      if (isSelected) {
        final glowPaint = Paint()
          ..color = colorScheme.primary.withOpacity(0.2 + sin(animationValue * 2 * pi) * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(position, radius + 8, glowPaint);
      }

      final nodePaint = Paint()
        ..color = isSelected 
            ? colorScheme.primary
            : _getNodeColor(note.type)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, radius, nodePaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, radius, borderPaint);

      final iconPainter = TextPainter(
        text: TextSpan(
          text: _getNodeIcon(note.type),
          style: TextStyle(
            fontSize: isSelected ? 18 : 14,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          position.dx - iconPainter.width / 2,
          position.dy - iconPainter.height / 2,
        ),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: note.title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
        ellipsis: '...',
      );
      labelPainter.layout(maxWidth: 80);
      labelPainter.paint(
        canvas,
        Offset(
          position.dx - labelPainter.width / 2,
          position.dy + radius + 8,
        ),
      );
    }
  }

  Color _getNodeColor(NoteType type) {
    switch (type) {
      case NoteType.markdown:
        return const Color(0xFF6366F1);
      case NoteType.chat:
        return const Color(0xFF10B981);
      case NoteType.googleDocs:
        return const Color(0xFFF59E0B);
    }
  }

  String _getNodeIcon(NoteType type) {
    switch (type) {
      case NoteType.markdown:
        return '📝';
      case NoteType.chat:
        return '💬';
      case NoteType.googleDocs:
        return '📄';
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedNoteId != selectedNoteId ||
        oldDelegate.notes != notes;
  }
}
