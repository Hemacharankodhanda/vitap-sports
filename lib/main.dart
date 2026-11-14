/// VIT-AP Sports — App entry point.
///
/// Initializes Supabase, sets up Riverpod, applies theme, and launches the router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/local_prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Flutter Binding Initialized');

  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
    );
    debugPrint('Supabase Initialized');
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  debugPrint('Initializing SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();

  // Pre-load saved ThemeMode to eliminate cold-start theme flash
  final themeModeStr = prefs.getString('app_theme_mode');
  ThemeMode initialThemeMode = ThemeMode.system;
  if (themeModeStr == 'light') initialThemeMode = ThemeMode.light;
  if (themeModeStr == 'dark') initialThemeMode = ThemeMode.dark;

  debugPrint('Calling runApp...');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: const VitapSportsApp(),
    ),
  );
  debugPrint('runApp called');
}

class VitapSportsApp extends ConsumerWidget {
  const VitapSportsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'VIT-AP Sports',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeState.accentColor.color),
      darkTheme: AppTheme.dark(themeState.accentColor.color),
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}
