import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected via [ProviderScope] overrides in [bootstrap].
/// All datasources read this instead of calling [SharedPreferences.getInstance]
/// directly, keeping them synchronous-friendly and fully testable.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'Call SharedPreferences.getInstance() in bootstrap() and pass it as an override.',
  );
});
