import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

// Available accent colors
enum AppAccentColor {
  orange(AppColors.accent, 'Orange'),
  blue(Colors.blue, 'Blue'),
  green(Colors.green, 'Green'),
  purple(Colors.purple, 'Purple'),
  red(Colors.redAccent, 'Red');

  const AppAccentColor(this.color, this.label);
  final Color color;
  final String label;
}

class AppThemeState {
  const AppThemeState({
    this.themeMode = ThemeMode.system,
    this.accentColor = AppAccentColor.orange,
  });

  final ThemeMode themeMode;
  final AppAccentColor accentColor;

  AppThemeState copyWith({
    ThemeMode? themeMode,
    AppAccentColor? accentColor,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class AppThemeNotifier extends StateNotifier<AppThemeState> {
  AppThemeNotifier() : super(const AppThemeState()) {
    _loadPreferences();
  }

  static const _themeModeKey = 'app_theme_mode';
  static const _accentColorKey = 'app_accent_color';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load ThemeMode
    final themeModeStr = prefs.getString(_themeModeKey);
    ThemeMode mode = ThemeMode.system;
    if (themeModeStr == 'light') mode = ThemeMode.light;
    if (themeModeStr == 'dark') mode = ThemeMode.dark;

    // Load AccentColor
    final accentColorStr = prefs.getString(_accentColorKey);
    AppAccentColor color = AppAccentColor.orange;
    for (final ac in AppAccentColor.values) {
      if (ac.name == accentColorStr) {
        color = ac;
        break;
      }
    }

    state = state.copyWith(themeMode: mode, accentColor: color);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setAccentColor(AppAccentColor color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, color.name);
  }
}

final themeProvider = StateNotifierProvider<AppThemeNotifier, AppThemeState>((ref) {
  return AppThemeNotifier();
});
