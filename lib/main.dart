import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final storageService = StorageService();
  await storageService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storageService),
        ChangeNotifierProvider.value(value: settingsService),
      ],
      child: const InkwellApp(),
    ),
  );
}

class InkwellApp extends StatelessWidget {
  const InkwellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
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
  }
}
