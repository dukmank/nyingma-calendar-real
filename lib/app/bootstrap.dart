import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/language_provider.dart';
import '../core/services/shared_preferences_provider.dart';
import '../core/services/weather_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/remote_data_cache.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Init notification service ──────────────────────────────────────────
  await NotificationService.init();

  // ── Init SharedPreferences once at startup ─────────────────────────────
  // Injecting the instance via ProviderScope overrides means every datasource
  // that needs it gets a synchronous reference — no repeated async getInstance
  // calls scattered across the codebase.
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getBool(AppConstants.spLanguage) ?? false;
  final savedTempCelsius = prefs.getBool(AppConstants.spTempUnitCelsius) ?? false;

  // ── Sync JSON data from B2 CDN ─────────────────────────────────────────
  // Fetches manifest.json, downloads only files whose hash has changed.
  // Silently fails (returns SyncResult.failed) when offline — app uses
  // previously cached files or bundled assets.
  final cache = RemoteDataCache(http.Client(), prefs);
  await cache.syncIfNeeded();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the SharedPreferences singleton
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Restore the last-saved language choice so the app starts in the
        // correct language without any flash of wrong content.
        languageProvider.overrideWith((ref) => savedLanguage),
        // Restore temperature unit preference (Celsius/Fahrenheit)
        tempUnitCelsiusProvider.overrideWith((ref) => savedTempCelsius),
      ],
      child: const NyingmapaApp(),
    ),
  );
}
