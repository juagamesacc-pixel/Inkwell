import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  'Appearance',
                  Icons.palette_outlined,
                  [
                    _buildThemeTile(context, settings),
                    _buildAccentColorTile(context, settings),
                    _buildFontSizeTile(context, settings),
                    _buildFontFamilyTile(context, settings),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Animations',
                  Icons.animation,
                  [
                    _buildAnimationsToggle(context, settings),
                    _buildAnimationSpeedTile(context, settings),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Editor',
                  Icons.edit_note,
                  [
                    _buildEditorModeTile(context, settings),
                    _buildLineNumbersTile(context, settings),
                    _buildWordWrapTile(context, settings),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Chat Viewer',
                  Icons.chat_bubble_outline,
                  [
                    _buildBubbleStyleTile(context, settings),
                    _buildShowThoughtsTile(context, settings),
                    _buildShowTimestampsTile(context, settings),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Graph',
                  Icons.graphic_eq,
                  [
                    _buildGraphLayoutTile(context, settings),
                  ],
                ),
                const SizedBox(height: 32),
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
    List<Widget> children,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

  Widget _buildThemeTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.dark_mode),
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto, size: 18),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (selection) {
          settings.setThemeMode(selection.first);
        },
      ),
    );
  }

  Widget _buildAccentColorTile(BuildContext context, SettingsService settings) {
    final colors = [
      AppColors.primaryLight,
      AppColors.rose,
      AppColors.amber,
      AppColors.emerald,
      AppColors.sky,
      AppColors.violet,
      AppColors.pink,
      AppColors.teal,
      AppColors.orange,
    ];

    return ListTile(
      leading: const Icon(Icons.color_lens),
      title: const Text('Accent Color'),
      subtitle: const Text('Choose your accent color'),
      trailing: Wrap(
        spacing: 4,
        children: colors.map((color) {
          final isSelected = settings.accentColor.value == color.value;
          return GestureDetector(
            onTap: () => settings.setAccentColor(color),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2,
                      )
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSizeTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('Font Size'),
      subtitle: Text('${settings.fontSize.round()}px'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: settings.fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          onChanged: (value) => settings.setFontSize(value),
        ),
      ),
    );
  }

  Widget _buildFontFamilyTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.font_download),
      title: const Text('Font Family'),
      trailing: DropdownButton<String>(
        value: settings.fontFamily,
        items: const [
          DropdownMenuItem(value: 'Inter', child: Text('Inter')),
          DropdownMenuItem(value: 'JetBrainsMono', child: Text('JetBrains Mono')),
          DropdownMenuItem(value: 'FiraCode', child: Text('Fira Code')),
        ],
        onChanged: (value) {
          if (value != null) settings.setFontFamily(value);
        },
      ),
    );
  }

  Widget _buildAnimationsToggle(BuildContext context, SettingsService settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.animation),
      title: const Text('Enable Animations'),
      value: settings.animationsEnabled,
      onChanged: (value) => settings.setAnimationsEnabled(value),
    );
  }

  Widget _buildAnimationSpeedTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.speed),
      title: const Text('Animation Speed'),
      subtitle: Text('${settings.animationSpeed.toStringAsFixed(1)}x'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: settings.animationSpeed,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: settings.animationsEnabled
              ? (value) => settings.setAnimationSpeed(value)
              : null,
        ),
      ),
    );
  }

  Widget _buildEditorModeTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.edit_note),
      title: const Text('Editor Mode'),
      trailing: DropdownButton<String>(
        value: settings.editorMode,
        items: const [
          DropdownMenuItem(value: 'split', child: Text('Split View')),
          DropdownMenuItem(value: 'live', child: Text('Live Preview')),
          DropdownMenuItem(value: 'preview', child: Text('Preview Only')),
        ],
        onChanged: (value) {
          if (value != null) settings.setEditorMode(value);
        },
      ),
    );
  }

  Widget _buildLineNumbersTile(BuildContext context, SettingsService settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.numbers),
      title: const Text('Show Line Numbers'),
      value: settings.showLineNumbers,
      onChanged: (value) => settings.setShowLineNumbers(value),
    );
  }

  Widget _buildWordWrapTile(BuildContext context, SettingsService settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.wrap_text),
      title: const Text('Word Wrap'),
      value: settings.wordWrap,
      onChanged: (value) => settings.setWordWrap(value),
    );
  }

  Widget _buildBubbleStyleTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.chat_bubble),
      title: const Text('Chat Bubble Style'),
      trailing: DropdownButton<String>(
        value: settings.chatBubbleStyle,
        items: const [
          DropdownMenuItem(value: 'compact', child: Text('Compact')),
          DropdownMenuItem(value: 'comfortable', child: Text('Comfortable')),
          DropdownMenuItem(value: 'spacious', child: Text('Spacious')),
        ],
        onChanged: (value) {
          if (value != null) settings.setChatBubbleStyle(value);
        },
      ),
    );
  }

  Widget _buildShowThoughtsTile(BuildContext context, SettingsService settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.psychology),
      title: const Text('Show Thoughts'),
      subtitle: const Text('Display model thinking process'),
      value: settings.showThoughts,
      onChanged: (value) => settings.setShowThoughts(value),
    );
  }

  Widget _buildShowTimestampsTile(BuildContext context, SettingsService settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.access_time),
      title: const Text('Show Timestamps'),
      value: settings.showTimestamps,
      onChanged: (value) => settings.setShowTimestamps(value),
    );
  }

  Widget _buildGraphLayoutTile(BuildContext context, SettingsService settings) {
    return ListTile(
      leading: const Icon(Icons.account_tree),
      title: const Text('Graph Layout'),
      trailing: DropdownButton<String>(
        value: settings.graphLayout,
        items: const [
          DropdownMenuItem(value: 'force', child: Text('Force Directed')),
          DropdownMenuItem(value: 'circular', child: Text('Circular')),
          DropdownMenuItem(value: 'tree', child: Text('Tree')),
        ],
        onChanged: (value) {
          if (value != null) settings.setGraphLayout(value);
        },
      ),
    );
  }
}
