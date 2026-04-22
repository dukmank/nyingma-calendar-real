import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../services/shared_preferences_provider.dart';

/// Global language toggle. false = English, true = Tibetan (བོད་སྐད།).
///
/// Initialised from SharedPreferences in [bootstrap] via ProviderScope
/// overrides, so the user's last-saved language is always restored on startup.
///
/// **To toggle** (e.g. in SettingsScreen):
/// ```dart
/// await ref.read(languageProvider.notifier).setTibetan(!currentValue);
/// ```
///
/// This writes through to SharedPreferences automatically.
final languageProvider = StateProvider<bool>((ref) => false);

/// Extension that lets settings screen persist the toggle in one call.
extension LanguageProviderX on StateController<bool> {
  /// Flip the language and persist to SharedPreferences.
  Future<void> setTibetan(bool value, WidgetRef ref) async {
    state = value;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.spLanguage, value);
  }
}

/// Convenience helper — pick the right string based on current language.
String langStr(bool tibetan, String en, String bo) => tibetan ? bo : en;
