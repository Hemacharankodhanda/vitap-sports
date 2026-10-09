/// VIT-AP Sports — Local Preferences Service.
///
/// Wraps SharedPreferences for typed local storage access.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provide the initialized SharedPreferences instance.
/// This must be overridden in main.dart after SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provide the LocalPrefsService.
final localPrefsProvider = Provider<LocalPrefsService>((ref) {
  return LocalPrefsService(ref.watch(sharedPreferencesProvider));
});

class LocalPrefsService {
  LocalPrefsService(this._prefs);
  final SharedPreferences _prefs;

  // ─── Keys ────────────────────────────────────────────────
  static const _keySelectedSport = 'selected_sport';
  static const _keyHasSeenOnboarding = 'has_seen_onboarding';

  // ─── Selected Sport ──────────────────────────────────────
  String get selectedSport => _prefs.getString(_keySelectedSport) ?? 'Cricket';

  Future<void> setSelectedSport(String sport) async {
    await _prefs.setString(_keySelectedSport, sport);
  }

  // ─── Onboarding ──────────────────────────────────────────
  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_keyHasSeenOnboarding, value);
  }
}
