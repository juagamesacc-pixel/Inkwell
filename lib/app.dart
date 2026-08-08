import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';

class InkwellApp extends StatelessWidget {
  const InkwellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              title: 'Inkwell',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(settings.accentColor),
              darkTheme: AppTheme.dark(settings.accentColor),
              themeMode: settings.themeMode,
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
