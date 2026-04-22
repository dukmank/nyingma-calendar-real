class AppConstants {
  AppConstants._();

  static const String appName = 'Nyingmapa Calendar';
  static const String appVersion = '1.0.0';

  // ── CDN base URL (Backblaze B2) ────────────────────────────────────────────
  // All assets — JSON data files AND images — are served from ONE B2 bucket.
  // Fill in your bucket download URL before deploying.
  //
  // Direct B2 URL format:
  //   'https://f003.backblazeb2.com/file/YOUR_BUCKET_NAME'
  //
  // With Cloudflare CDN (recommended — egress is free via Cloudflare):
  //   'https://cdn.nyingmapacalendar.org'
  //
  // Bucket folder layout (mirrors the local b2_upload/ directory):
  //   manifest.json
  //   data/calendar/2026_02.json  …
  //   data/events/events.json
  //   data/auspicious/auspicious.json
  //   data/reference/*.json  (astrology reference tables + astrology_cards_ref.json)
  //   images/losar.webp  …
  // Images bucket (flat — no subfolder): https://f005.backblazeb2.com/file/nyingma-assets2/losar.webp
  static const String cdnBaseUrl =
      'https://ittle-term-2262.phungducmanh18072005.workers.dev';

  // ── Manifest (hash-based cache invalidation) ──────────────────────────────
  /// Per-file hash manifest fetched on every launch to detect changed files.
  /// Only downloads files whose hash has changed since last sync.
  /// Structure: { "schema_version": 1, "data_version": "...", "files": { "path": { "hash": "...", ... }, ... } }
  static const String manifestUrl = '$cdnBaseUrl/data/manifest.json';

  // ── Relative data paths (passed to RemoteDataCache.getJson) ───────────────
  // These map 1-to-1 with the paths listed in manifest.json and the B2 bucket.
  // Updated: manifest-based sync
  // Monthly calendar: data/calendar/2026_04.json
  static String calendarPath(int year, int month) =>
      'data/calendar/${year}_${month.toString().padLeft(2, '0')}.json';

  // Full day detail: data/day_details/2026-04-03.json
  static String dayDetailPath(String dateKey) =>
      'data/day_details/$dateKey.json';

  static const String eventsPath     = 'data/events_index.json';
  static const String auspiciousPath = 'data/reference/auspicious_days_ref.json';

  /// Maps an astrology route key to its B2 JSON path under data/reference/.
  /// Key overrides: some route keys differ from the JSON filename.
  static String referencePath(String key) {
    const _overrides = {
      'auspicious_times':      'auspicious_timing',
      'restriction_activities':'daily_restrictions',
    };
    return 'data/reference/${_overrides[key] ?? key}.json';
  }

  // ── Image URL helper ───────────────────────────────────────────────────────
  /// All images are stored flat in the B2 bucket as .webp.
  /// e.g. 'losar' → 'https://f005.backblazeb2.com/file/nyingma-assets2/losar.webp'
  static String imageUrl(String key) => '$cdnBaseUrl/$key.webp';

  // Astrology item keys (15 items)
  static const List<String> astrologyKeys = [
    'auspicious_times',   // data/astrology/auspicious_timing.json
    'parkha',             // data/astrology/ (no JSON yet)
    'fire_rituals',       // data/astrology/fire_rituals.json
    'empty_vase',         // data/astrology/empty_vase.json
    'life_force_male',    // data/astrology/life_force_male.json
    'life_force_female',  // data/astrology/life_force_female.json
    'horse_death',        // data/astrology/horse_death.json
    'gu_mig',             // data/astrology/gu_mig.json
    'flag_days',          // data/astrology/flag_days.json
    'naga_days',          // data/astrology/naga_days.json
    'torma_offerings',    // data/astrology/torma_offerings.json
    'fatal_weekdays',     // data/astrology/fatal_weekdays.json
    'hair_cutting',       // data/astrology/hair_cutting.json
    'eye_twitching',      // data/astrology/eye_twitching.json
    'restriction_activities', // data/astrology/daily_restrictions.json
  ];

  // Bottom nav indices
  static const int navCalendar   = 0;
  static const int navAuspicious = 1;
  static const int navEvents     = 2;
  static const int navProfile    = 3;
  static const int navSettings   = 4;

  // Language codes
  static const String langEn = 'en';
  static const String langBo = 'bo';

  // ── Server API ──────────────────────────────────────────────────────────────
  /// Replace with your actual backend base URL before going to production.
  static const String apiBaseUrl  = 'https://api.nyingmapacalendar.org/v1';
  static const Duration apiTimeout = Duration(seconds: 15);

  // ── Supabase ───────────────────────────────────────────────────────────────
  // Giá trị được truyền qua --dart-define lúc build/run, KHÔNG hardcode ở đây.
  // Xem: dart_define.sh (local) hoặc .vscode/launch.json để chạy trong VS Code.
  // CI/CD: truyền qua GitHub Actions secrets hoặc Codemagic env vars.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  // Prefix all keys so they don't collide with future libraries.
  static const String spLanguage       = 'nmc_language';        // String
  static const String spUserProfile    = 'nmc_user_profile';    // JSON string
  static const String spPractices      = 'nmc_practices';       // JSON array
  static const String spUserEvents     = 'nmc_user_events';     // JSON array
  static const String spLastSyncedAt   = 'nmc_last_synced_at';  // ISO-8601
  static const String spOnboardingDone = 'nmc_onboarding_done'; // bool
  static const String spDataVersion    = 'nmc_data_version';    // e.g. '2026.1.0' — kept for compat
  static const String spFileHashes     = 'nmc_file_hashes';     // JSON map of {path: hash}
  static const String spTempUnitCelsius = 'nmc_temp_unit_celsius'; // bool — true = Celsius, false = Fahrenheit
  static const String spNewsCache       = 'nmc_news_cache';        // JSON string — cached news list
  static const String spNewsCachedAt   = 'nmc_news_cached_at';    // ISO-8601 — when cache was written
}

// Route names are defined in lib/app/router/route_names.dart
