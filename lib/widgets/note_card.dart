import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/colors.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
    this.onTogglePin,
    this.index = 0,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _hovered = false;

  (Color, Color, IconData) get _meta {
    switch (widget.note.type) {
      case NoteType.markdown:
        return (AppColors.markdownAccent, AppColors.markdownAccent.withValues(alpha: 0.7), Icons.edit_note_rounded);
      case NoteType.chat:
        return (AppColors.chatAccent, AppColors.chatAccent.withValues(alpha: 0.7), Icons.chat_bubble_rounded);
      case NoteType.googleDocs:
        return (AppColors.importedAccent, AppColors.importedAccent.withValues(alpha: 0.7), Icons.article_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final note = widget.note;
    final (accent, accentSoft, typeIcon) = _meta;
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.015 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: _hovered ? 0.13 : 0.09),
                            Colors.white.withValues(alpha: _hovered ? 0.08 : 0.045),
                          ]
                        : [
                            Colors.white.withValues(alpha: _hovered ? 0.98 : 0.88),
                            Colors.white.withValues(alpha: _hovered ? 0.9 : 0.7),
                          ],
                  ),
                  border: Border.all(
                    color: _hovered
                        ? accent.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hovered
                          ? accent.withValues(alpha: isDark ? 0.2 : 0.14)
                          : Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                      blurRadius: _hovered ? 30 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Accent glow top-right.
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: isDark ? 0.18 : 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accent.withValues(alpha: 0.22),
                                    accent.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Icon(typeIcon, size: 18, color: accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDate(note.modifiedAt),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (note.isPinned)
                              Icon(
                                Icons.push_pin_rounded,
                                size: 18,
                                color: accent,
                              ),
                            if (widget.onTogglePin != null && !note.isPinned)
                              IconButton(
                                icon: Icon(
                                  Icons.push_pin_outlined,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: widget.onTogglePin,
                                tooltip: 'Pin note',
                              ),
                            AnimatedOpacity(
                              opacity: _hovered || !isDark ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: colorScheme.error.withValues(alpha: 0.75),
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: widget.onDelete,
                                tooltip: 'Delete note',
                              ),
                            ),
                          ],
                        ),
                        if (note.hasContent) ...[
                          const SizedBox(height: 14),
                          Text(
                            _preview(note.content),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: note.tags.take(5).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: accent.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _FooterItem(
                              icon: Icons.notes_rounded,
                              text: '${note.wordCount} words',
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 14),
                            _FooterItem(
                              icon: Icons.schedule_rounded,
                              text: '${note.readingTime} min read',
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: accentSoft.withValues(alpha: 0.12),
                              ),
                              child: Text(
                                widget.note.type.label,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _preview(String content) {
    final cleaned = content
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'[#*`>~_\[\]|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > 160
        ? '${cleaned.substring(0, 160)}…'
        : cleaned;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FooterItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}
