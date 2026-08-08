import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = const Color(0xFF6366F1);
  double _fontSize = 16.0;
  bool _animationsEnabled = true;
  String _graphLayout = 'force';
  String _editorMode = 'split';
  String _chatBubbleStyle = 'comfortable';
  bool _showThoughts = true;
  bool _showTimestamps = true;
  String _fontFamily = 'Inter';
  double _animationSpeed = 1.0;
  bool _showLineNumbers = false;
  bool _wordWrap = true;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  double get fontSize => _fontSize;
  bool get animationsEnabled => _animationsEnabled;
  String get graphLayout => _graphLayout;
  String get editorMode => _editorMode;
  String get chatBubbleStyle => _chatBubbleStyle;
  bool get showThoughts => _showThoughts;
  bool get showTimestamps => _showTimestamps;
  String get fontFamily => _fontFamily;
  double get animationSpeed => _animationSpeed;
  bool get showLineNumbers => _showLineNumbers;
  bool get wordWrap => _wordWrap;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 2];
    _accentColor = Color(prefs.getInt('accentColor') ?? 0xFF6366F1);
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
    _graphLayout = prefs.getString('graphLayout') ?? 'force';
    _editorMode = prefs.getString('editorMode') ?? 'split';
    _chatBubbleStyle = prefs.getString('chatBubbleStyle') ?? 'comfortable';
    _showThoughts = prefs.getBool('showThoughts') ?? true;
    _showTimestamps = prefs.getBool('showTimestamps') ?? true;
    _fontFamily = prefs.getString('fontFamily') ?? 'Inter';
    _animationSpeed = prefs.getDouble('animationSpeed') ?? 1.0;
    _showLineNumbers = prefs.getBool('showLineNumbers') ?? false;
    _wordWrap = prefs.getBool('wordWrap') ?? true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('accentColor', _accentColor.value);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setBool('animationsEnabled', _animationsEnabled);
    await prefs.setString('graphLayout', _graphLayout);
    await prefs.setString('editorMode', _editorMode);
    await prefs.setString('chatBubbleStyle', _chatBubbleStyle);
    await prefs.setBool('showThoughts', _showThoughts);
    await prefs.setBool('showTimestamps', _showTimestamps);
    await prefs.setString('fontFamily', _fontFamily);
    await prefs.setDouble('animationSpeed', _animationSpeed);
    await prefs.setBool('showLineNumbers', _showLineNumbers);
    await prefs.setBool('wordWrap', _wordWrap);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _save();
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _save();
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _save();
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    await _save();
    notifyListeners();
  }

  Future<void> setGraphLayout(String layout) async {
    _graphLayout = layout;
    await _save();
    notifyListeners();
  }

  Future<void> setEditorMode(String mode) async {
    _editorMode = mode;
    await _save();
    notifyListeners();
  }

  Future<void> setChatBubbleStyle(String style) async {
    _chatBubbleStyle = style;
    await _save();
    notifyListeners();
  }

  Future<void> setShowThoughts(bool show) async {
    _showThoughts = show;
    await _save();
    notifyListeners();
  }

  Future<void> setShowTimestamps(bool show) async {
    _showTimestamps = show;
    await _save();
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    await _save();
    notifyListeners();
  }

  Future<void> setAnimationSpeed(double speed) async {
    _animationSpeed = speed;
    await _save();
    notifyListeners();
  }

  Future<void> setShowLineNumbers(bool show) async {
    _showLineNumbers = show;
    await _save();
    notifyListeners();
  }

  Future<void> setWordWrap(bool wrap) async {
    _wordWrap = wrap;
    await _save();
    notifyListeners();
  }
}
