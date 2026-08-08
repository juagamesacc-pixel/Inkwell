import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../theme/colors.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/animated_gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ).animate().fadeIn().slideX(
                      begin: -0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSection(
                    context,
                    'Appearance',
                    Icons.palette_rounded,
                    [
                      _buildThemeTile(context, settings),
                      _buildAccentColorTile(context, settings),
                      _buildFontSizeTile(context, settings),
                      _buildFontFamilyTile(context, settings),
                    ],
                    delay: 100,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    'Animations',
                    Icons.animation_rounded,
                    [
                      _buildAnimationsToggle(context, settings),
                      _buildAnimationSpeedTile(context, settings),
                    ],
                    delay: 200,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    'Editor',
                    Icons.edit_note_rounded,
                    [
                      _buildEditorModeTile(context, settings),
                      _buildLineNumbersTile(context, settings),
                      _buildWordWrapTile(context, settings),
                    ],
                    delay: 300,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    'Chat Viewer',
                    Icons.chat_bubble_rounded,
                    [
                      _buildBubbleStyleTile(context, settings),
                      _buildShowThoughtsTile(context, settings),
                      _buildShowTimestampsTile(context, settings),
                    ],
                    delay: 400,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    'Graph',
                    Icons.graphic_eq_rounded,
                    [
                      _buildGraphLayoutTile(context, settings),
                    ],
                    delay: 500,
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children, {
    int delay = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.2),
                        colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: colorScheme.primary,
                  ),
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
    ).animate().fadeIn(
          delay: Duration(milliseconds: delay),
          duration: const Duration(milliseconds: 400),
        ).slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
  }

  Widget _buildThemeTile(BuildContext context, SettingsService settings) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SettingsTile(
      icon: Icons.dark_mode_rounded,
      title: 'Theme',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.primary.withOpacity(0.1),
        ),
        child: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded, size: 18),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_rounded, size: 18),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (selection) {
            settings.setThemeMode(selection.first);
          },
        ),
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

    return _SettingsTile(
      icon: Icons.color_lens_rounded,
      title: 'Accent Color',
      subtitle: 'Choose your accent color',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: colors.map((color) {
          final isSelected = settings.accentColor.value == color.value;
          return GestureDetector(
            onTap: () => settings.setAccentColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.transparent,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
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
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          thumbColor: Theme.of(context).colorScheme.primary,
          overlayColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
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
    return _SettingsTile(
      icon: Icons.font_download_rounded,
      title: 'Font Family',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: DropdownButton<String>(
          value: settings.fontFamily,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'Inter', child: Text('Inter')),
            DropdownMenuItem(
                value: 'JetBrainsMono', child: Text('JetBrains Mono')),
            DropdownMenuItem(value: 'FiraCode', child: Text('Fira Code')),
          ],
          onChanged: (value) {
            if (value != null) settings.setFontFamily(value);
          },
        ),
      ),
    );
  }

  Widget _buildAnimationsToggle(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.animation_rounded,
      title: 'Enable Animations',
      child: Switch.adaptive(
        value: settings.animationsEnabled,
        onChanged: (value) => settings.setAnimationsEnabled(value),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAnimationSpeedTile(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.speed_rounded,
      title: 'Animation Speed',
      subtitle: '${settings.animationSpeed.toStringAsFixed(1)}x',
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          thumbColor: Theme.of(context).colorScheme.primary,
          overlayColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
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
    return _SettingsTile(
      icon: Icons.edit_note_rounded,
      title: 'Editor Mode',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: DropdownButton<String>(
          value: settings.editorMode,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'split', child: Text('Split View')),
            DropdownMenuItem(value: 'live', child: Text('Live Preview')),
            DropdownMenuItem(value: 'preview', child: Text('Preview Only')),
          ],
          onChanged: (value) {
            if (value != null) settings.setEditorMode(value);
          },
        ),
      ),
    );
  }

  Widget _buildLineNumbersTile(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.numbers_rounded,
      title: 'Show Line Numbers',
      child: Switch.adaptive(
        value: settings.showLineNumbers,
        onChanged: (value) => settings.setShowLineNumbers(value),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildWordWrapTile(BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.wrap_text_rounded,
      title: 'Word Wrap',
      child: Switch.adaptive(
        value: settings.wordWrap,
        onChanged: (value) => settings.setWordWrap(value),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildBubbleStyleTile(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.chat_bubble_rounded,
      title: 'Chat Bubble Style',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: DropdownButton<String>(
          value: settings.chatBubbleStyle,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'compact', child: Text('Compact')),
            DropdownMenuItem(value: 'comfortable', child: Text('Comfortable')),
            DropdownMenuItem(value: 'spacious', child: Text('Spacious')),
          ],
          onChanged: (value) {
            if (value != null) settings.setChatBubbleStyle(value);
          },
        ),
      ),
    );
  }

  Widget _buildShowThoughtsTile(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.psychology_rounded,
      title: 'Show Thoughts',
      subtitle: 'Display model thinking process',
      child: Switch.adaptive(
        value: settings.showThoughts,
        onChanged: (value) => settings.setShowThoughts(value),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildShowTimestampsTile(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.access_time_rounded,
      title: 'Show Timestamps',
      child: Switch.adaptive(
        value: settings.showTimestamps,
        onChanged: (value) => settings.setShowTimestamps(value),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildGraphLayoutTile(
      BuildContext context, SettingsService settings) {
    return _SettingsTile(
      icon: Icons.account_tree_rounded,
      title: 'Graph Layout',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: DropdownButton<String>(
          value: settings.graphLayout,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: 'force', child: Text('Force Directed')),
            DropdownMenuItem(value: 'circular', child: Text('Circular')),
            DropdownMenuItem(value: 'tree', child: Text('Tree')),
          ],
          onChanged: (value) {
            if (value != null) settings.setGraphLayout(value);
          },
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
