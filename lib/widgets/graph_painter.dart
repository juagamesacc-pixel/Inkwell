import 'dart:math';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/colors.dart';

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
    final pulse = (sin(animationValue * 2 * pi) + 1) / 2;

    for (var entry in graph.entries) {
      final sourcePos = nodePositions[entry.key];
      if (sourcePos == null) continue;

      for (var targetId in entry.value) {
        final targetPos = nodePositions[targetId];
        if (targetPos == null) continue;

        final isSelected =
            selectedNoteId == entry.key || selectedNoteId == targetId;

        final base = isSelected ? colorScheme.primary : const Color(0xFF94A3B8);
        final paint = Paint()
          ..color = base.withValues(alpha: isSelected ? 0.65 : 0.28 + pulse * 0.15)
          ..strokeWidth = isSelected ? 2.5 : 1.4
          ..style = PaintingStyle.stroke;

        if (isSelected) {
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        }

        final path = Path();
        path.moveTo(sourcePos.dx, sourcePos.dy);
        final mid = Offset(
          (sourcePos.dx + targetPos.dx) / 2,
          (sourcePos.dy + targetPos.dy) / 2 - 46,
        );
        path.quadraticBezierTo(
          mid.dx,
          mid.dy,
          targetPos.dx,
          targetPos.dy,
        );
        canvas.drawPath(path, paint);

        // Animated dash traveling along the edge.
        final dashPaint = Paint()
          ..color = (isSelected ? colorScheme.primary : const Color(0xFFCBD5E1))
              .withValues(alpha: 0.8)
          ..strokeWidth = isSelected ? 3 : 2
          ..strokeCap = StrokeCap.round;
        final t = (animationValue + entry.key.hashCode % 10 / 10) % 1.0;
        _drawDash(canvas, sourcePos, mid, targetPos, t, dashPaint);

        _drawArrow(canvas, targetPos, sourcePos, base.withValues(alpha: 0.7));
      }
    }
  }

  void _drawDash(Canvas canvas, Offset a, Offset c, Offset b, double t, Paint paint) {
    final p0 = _quadPoint(a, c, b, t);
    final p1 = _quadPoint(a, c, b, (t + 0.06).clamp(0.0, 1.0));
    canvas.drawLine(p0, p1, paint);
  }

  Offset _quadPoint(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  void _drawArrow(Canvas canvas, Offset target, Offset source, Color color) {
    final direction = source - target;
    final distance = direction.distance;
    if (distance == 0) return;

    final normalized = direction / distance;
    const arrowSize = 9.0;
    final arrowPoint = target + normalized * 30;
    final left = arrowPoint +
        Offset(
          -normalized.dy * arrowSize / 2 + normalized.dx * arrowSize / 2,
          normalized.dx * arrowSize / 2 + normalized.dy * arrowSize / 2,
        );
    final right = arrowPoint +
        Offset(
          normalized.dy * arrowSize / 2 + normalized.dx * arrowSize / 2,
          -normalized.dx * arrowSize / 2 + normalized.dy * arrowSize / 2,
        );

    final arrowPath = Path()
      ..moveTo(arrowPoint.dx, arrowPoint.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()..color = color,
    );
  }

  void _drawNodes(Canvas canvas) {
    for (var note in notes) {
      final position = nodePositions[note.id];
      if (position == null) continue;

      final isSelected = selectedNoteId == note.id;
      final radius = isSelected ? 26.0 : 20.0;
      final baseColor = _getNodeColor(note.type);

      // Soft ambient glow.
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withValues(alpha: isSelected ? 0.5 : 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: position, radius: radius * 3));
      canvas.drawCircle(position, radius * (isSelected ? 2.6 : 2.1), glowPaint);

      // Node body with vertical gradient.
      final nodePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(baseColor, Colors.white, isSelected ? 0.18 : 0.1)!,
            baseColor,
          ],
        ).createShader(
          Rect.fromCircle(center: position, radius: radius),
        );
      canvas.drawCircle(position, radius, nodePaint);

      // Ring border.
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: isSelected ? 0.95 : 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.6;
      canvas.drawCircle(position, radius, borderPaint);

      // Selected halo ring.
      if (isSelected) {
        final ring = Paint()
          ..color = baseColor.withValues(alpha: 0.6 + sin(animationValue * 2 * pi) * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(position, radius + 6 + sin(animationValue * 2 * pi) * 3, ring);
      }

      // Node glyph (emoji).
      final iconPainter = TextPainter(
        text: TextSpan(
          text: _getNodeIcon(note.type),
          style: TextStyle(fontSize: isSelected ? 17 : 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          position.dx - iconPainter.width / 2,
          position.dy - iconPainter.height / 2,
        ),
      );

      // Label.
      final labelPainter = TextPainter(
        text: TextSpan(
          text: note.title,
          style: TextStyle(
            fontSize: isSelected ? 12.5 : 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 90);
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
        return AppColors.markdownAccent;
      case NoteType.chat:
        return AppColors.chatAccent;
      case NoteType.googleDocs:
        return AppColors.importedAccent;
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
