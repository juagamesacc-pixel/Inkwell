import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';
import '../utils/zip_handler.dart';
import '../widgets/glass/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalize your experience',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  'Appearance',
                  Icons.palette_rounded,
                  AppColors.indigo,
                  [
                    _buildThemeTile(context, settings),
                    _buildAccentColorTile(context, settings),
                    _buildFontSizeTile(context, settings),
                    _buildFontFamilyTile(context, settings),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSection(
                  context,
                  'Editor',
                  Icons.edit_note_rounded,
                  AppColors.violet,
                  [
                    _buildEditorModeTile(context, settings),
                    _buildLineNumbersTile(context, settings),
                    _buildWordWrapTile(context, settings),
                    _buildAnimationsToggle(context, settings),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSection(
                  context,
                  'Chat Viewer',
                  Icons.chat_bubble_rounded,
                  AppColors.emerald,
                  [
                    _buildBubbleStyleTile(context, settings),
                    _buildShowThoughtsTile(context, settings),
                    _buildShowTimestampsTile(context, settings),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSection(
                  context,
                  'Knowledge Graph',
                  Icons.graphic_eq_rounded,
                  AppColors.pink,
                  [
                    _buildGraphLayoutTile(context, settings),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDataSection(context),
                const SizedBox(height: 14),
                _buildAboutSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.1)],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ---- Data section -------------------------------------------------------

  Widget _buildDataSection(BuildContext context) {
    return _buildSection(context, 'Data', Icons.folder_zip_rounded, AppColors.amber, [
      _DataTile(
        icon: Icons.upload_file_rounded,
        title: 'Import notes',
        subtitle: 'Markdown, chat JSON, or zip backup',
        color: AppColors.amber,
        onTap: () => _import(context),
      ),
      _DataTile(
        icon: Icons.download_rounded,
        title: 'Export all notes',
        subtitle: 'Create a .zip backup of everything',
        color: AppColors.sky,
        onTap: () => _export(context),
      ),
      _DataTile(
        icon: Icons.restart_alt_rounded,
        title: 'Reset preferences',
        subtitle: 'Restore default settings',
        color: AppColors.rose,
        onTap: () => _reset(context),
      ),
    ]);
  }

  Widget _buildAboutSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.oceanGradient,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inkwell',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version 1.0.0 · Your second brain',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: AppColors.oceanGradient,
            ),
            child: const Text(
              'MIT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'json', 'zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;
      if (!context.mounted) return;
      final storage = context.read<StorageService>();
      final text = utf8.decode(bytes, allowMalformed: true);
      final name = file.name.toLowerCase();

      if (name.endsWith('.zip')) {
        final imported = await ZipHandler.importFromZip(bytes, storage);
        if (!context.mounted) return;
        _toast(context, 'Imported ${imported.length} notes from zip');
      } else if (name.endsWith('.md')) {
        await storage.importMarkdown(file.name, text);
        if (!context.mounted) return;
        _toast(context, 'Imported "${file.name}"');
      } else if (name.endsWith('.json')) {
        await storage.importChatJson(file.name, text);
        if (!context.mounted) return;
        _toast(context, 'Imported "${file.name}"');
      } else {
        if (!context.mounted) return;
        _toast(context, 'Unsupported file type', error: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, 'Import failed: $e', error: true);
    }
  }

  Future<void> _export(BuildContext context) async {
    try {
      final storage = context.read<StorageService>();
      if (storage.notes.isEmpty) {
        _toast(context, 'No notes to export yet');
        return;
      }
      final file = await ZipHandler.exportNotesToZip(storage.notes, storage);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip')],
        text: 'Inkwell notes backup',
      );
    } catch (e) {
      if (!context.mounted) return;
      _toast(context, 'Export failed: $e', error: true);
    }
  }

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset preferences?'),
        content: const Text('This will restore all settings to defaults. Your notes are unaffected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SettingsService>().reset();
      if (!context.mounted) return;
      _toast(context, 'Settings restored to defaults');
    }
  }

  void _toast(BuildContext context, String message, {bool error = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---- Tiles --------------------------------------------------------------

  Widget _buildThemeTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.dark_mode_rounded,
      title: 'Theme',
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_rounded, size: 17),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_rounded, size: 17),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_rounded, size: 17),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (selection) => settings.setThemeMode(selection.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildAccentColorTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.color_lens_rounded,
      title: 'Accent Color',
      subtitle: 'A gradient is generated from your accent',
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: AppColors.accentOptions.map((color) {
          final isSelected = settings.accentColor.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () => settings.setAccentColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Color.lerp(color, Colors.white, 0.15)!],
                ),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSizeTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.text_fields_rounded,
      title: 'Font Size',
      subtitle: '${settings.fontSize.round()}px',
      child: SizedBox(
        width: 130,
        child: Slider(
          value: settings.fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          onChanged: settings.setFontSize,
        ),
      ),
    );
  }

  Widget _buildFontFamilyTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.font_download_rounded,
      title: 'Font Family',
      child: _Dropdown(
        value: settings.fontFamily,
        items: const [
          DropdownMenuItem(value: 'Inter', child: Text('Inter')),
          DropdownMenuItem(value: 'JetBrainsMono', child: Text('JetBrains Mono')),
          DropdownMenuItem(value: 'FiraCode', child: Text('Fira Code')),
        ],
        onChanged: (v) => settings.setFontFamily(v),
      ),
    );
  }

  Widget _buildEditorModeTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.edit_note_rounded,
      title: 'Default Editor Mode',
      child: _Dropdown(
        value: settings.editorMode,
        items: const [
          DropdownMenuItem(value: 'live', child: Text('Editor')),
          DropdownMenuItem(value: 'split', child: Text('Split View')),
          DropdownMenuItem(value: 'preview', child: Text('Preview')),
        ],
        onChanged: (v) => settings.setEditorMode(v),
      ),
    );
  }

  Widget _buildLineNumbersTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.numbers_rounded,
      title: 'Line Numbers',
      subtitle: 'Shown in the editor',
      trailing: Switch.adaptive(
        value: settings.showLineNumbers,
        onChanged: settings.setShowLineNumbers,
      ),
    );
  }

  Widget _buildWordWrapTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.wrap_text_rounded,
      title: 'Word Wrap',
      trailing: Switch.adaptive(
        value: settings.wordWrap,
        onChanged: settings.setWordWrap,
      ),
    );
  }

  Widget _buildAnimationsToggle(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.animation_rounded,
      title: 'Enable Animations',
      subtitle: '${settings.animationSpeed.toStringAsFixed(1)}x speed',
      trailing: Switch.adaptive(
        value: settings.animationsEnabled,
        onChanged: settings.setAnimationsEnabled,
      ),
    );
  }

  Widget _buildBubbleStyleTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.chat_bubble_rounded,
      title: 'Chat Bubble Style',
      child: _Dropdown(
        value: settings.chatBubbleStyle,
        items: const [
          DropdownMenuItem(value: 'compact', child: Text('Compact')),
          DropdownMenuItem(value: 'comfortable', child: Text('Comfortable')),
          DropdownMenuItem(value: 'spacious', child: Text('Spacious')),
        ],
        onChanged: (v) => settings.setChatBubbleStyle(v),
      ),
    );
  }

  Widget _buildShowThoughtsTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.psychology_rounded,
      title: 'Show Model Thoughts',
      subtitle: 'Display the thinking process',
      trailing: Switch.adaptive(
        value: settings.showThoughts,
        onChanged: settings.setShowThoughts,
      ),
    );
  }

  Widget _buildShowTimestampsTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.access_time_rounded,
      title: 'Show Timestamps',
      trailing: Switch.adaptive(
        value: settings.showTimestamps,
        onChanged: settings.setShowTimestamps,
      ),
    );
  }

  Widget _buildGraphLayoutTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.account_tree_rounded,
      title: 'Graph Layout',
      child: _Dropdown(
        value: settings.graphLayout,
        items: const [
          DropdownMenuItem(value: 'force', child: Text('Force Directed')),
          DropdownMenuItem(value: 'circular', child: Text('Circular')),
          DropdownMenuItem(value: 'tree', child: Text('Tree')),
        ],
        onChanged: (v) => settings.setGraphLayout(v),
      ),
    );
  }
}

// ---- Data tile --------------------------------------------------------------

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DataTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.1)],
                ),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Reusable tile ------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (child != null)
            Flexible(child: child!),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
