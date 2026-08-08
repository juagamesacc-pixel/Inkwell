import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteType = widget.note.type;

    // Gradient colors based on note type
    List<Color> gradientColors;
    Color accentColor;
    IconData typeIcon;

    switch (noteType) {
      case NoteType.markdown:
        gradientColors = isDark
            ? [
                const Color(0xFF6366F1).withOpacity(0.15),
                const Color(0xFF818CF8).withOpacity(0.08),
              ]
            : [
                const Color(0xFF6366F1).withOpacity(0.1),
                const Color(0xFF818CF8).withOpacity(0.05),
              ];
        accentColor = const Color(0xFF6366F1);
        typeIcon = Icons.edit_note_rounded;
        break;
      case NoteType.chat:
        gradientColors = isDark
            ? [
                const Color(0xFF10B981).withOpacity(0.15),
                const Color(0xFF34D399).withOpacity(0.08),
              ]
            : [
                const Color(0xFF10B981).withOpacity(0.1),
                const Color(0xFF34D399).withOpacity(0.05),
              ];
        accentColor = const Color(0xFF10B981);
        typeIcon = Icons.chat_bubble_rounded;
        break;
      case NoteType.googleDocs:
        gradientColors = isDark
            ? [
                const Color(0xFFF59E0B).withOpacity(0.15),
                const Color(0xFFFBBF24).withOpacity(0.08),
              ]
            : [
                const Color(0xFFF59E0B).withOpacity(0.1),
                const Color(0xFFFBBF24).withOpacity(0.05),
              ];
        accentColor = const Color(0xFFF59E0B);
        typeIcon = Icons.article_rounded;
        break;
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      border: Border.all(
                        color: _isHovered
                            ? accentColor.withOpacity(0.3)
                            : Colors.white.withOpacity(isDark ? 0.08 : 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? accentColor.withOpacity(0.15)
                              : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: _isHovered ? 24 : 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.2),
                                    accentColor.withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                typeIcon,
                                size: 18,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Title and date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.note.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(widget.note.modifiedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete button
                            if (widget.onDelete != null)
                              AnimatedOpacity(
                                opacity: _isHovered ? 1 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.7),
                                  ),
                                  onPressed: widget.onDelete,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.1),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (widget.note.content.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.note.content.substring(
                                0,
                                widget.note.content.length.clamp(0, 120)),
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (widget.note.tags.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.note.tags.take(4).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: accentColor.withOpacity(0.1),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.15),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor.withOpacity(0.8),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
