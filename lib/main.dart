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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter Binding Initialized');

  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
    );
    print('✅ Supabase Initialized');
  } catch (e) {
    print('❌ Supabase Init Error: $e');
  }

  print(' Initializing SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();

  print(' Calling runApp...');
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VitapSportsApp(),
    ),
  );
  print('✅ runApp called');
}

class VitapSportsApp extends ConsumerWidget {
  const VitapSportsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'VIT-AP Sports',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
