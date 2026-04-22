import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// dart:io is mobile/desktop only — conditionally imported via helper below.
import 'remote_data_cache_io.dart'
    if (dart.library.html) 'remote_data_cache_web.dart' as platform;

import '../constants/app_constants.dart';
import 'shared_preferences_provider.dart';

// ── Result type ────────────────────────────────────────────────────────────

enum SyncResult {
  /// Local version matches remote — nothing downloaded.
  upToDate,

  /// New version detected; all files downloaded and saved.
  updated,

  /// Network error — app continues with previously cached files.
  failed,
}

// ── Service ────────────────────────────────────────────────────────────────

/// Hash-based remote data caching strategy:
///
///  **Startup sync** (`syncIfNeeded`):
///    1. Fetch `manifest.json` from the B2 CDN (~2 KB) containing per-file SHA-256 hashes.
///    2. Load stored file hashes from SharedPreferences (key: `spFileHashes`, JSON map).
///    3. Compare each file's hash in manifest with stored hash.
///    4. Download only files where hash differs (in parallel, max 4 concurrent).
///    5. Update stored hashes and data_version in SharedPreferences.
///
///  **Runtime reads** (`getJson`):
///    - Always read from local cache (fast, fully offline).
///    - Falls back to an on-demand fetch only if a file is missing entirely.
///
///  **Storage backend** (automatic):
///    - **Mobile / Desktop**: files on disk via `path_provider`.
///    - **Web**: JSON strings in `SharedPreferences` (backed by `localStorage`).
///
///  **Images**: served from the same B2 CDN under the `images/` prefix.
///  Loaded lazily by `AppNetworkImage` via `cached_network_image`; this
///  service handles JSON only — images bypass the version-sync flow.
class RemoteDataCache {
  final http.Client _client;
  final SharedPreferences _prefs;

  static const Duration _versionTimeout = Duration(seconds: 10);
  static const Duration _fileTimeout    = Duration(seconds: 30);

  /// Max concurrent B2 downloads during sync (avoids hammering the CDN).
  static const int _maxConcurrent = 4;

  /// Prefix for SharedPreferences keys used as the web JSON cache.
  static const String _webCachePrefix = 'nmc_json_cache__';

  /// In-memory JSON cache — parsed once, reused for the app lifetime.
  /// Prevents repeated disk reads + JSON.decode on every provider rebuild.
  final Map<String, Map<String, dynamic>> _memCache = {};

  RemoteDataCache(this._client, this._prefs);

  // ── Startup sync ───────────────────────────────────────────────────────────

  /// Call once during app initialisation.
  /// Returns quickly when all local files have matching hashes.
  /// Updated: manifest-based sync
  Future<SyncResult> syncIfNeeded() async {
    try {
      final manifest = await _fetchManifest();
      final remoteFiles =
          (manifest['files'] as Map<String, dynamic>?)?.cast<String, Map<String, dynamic>>() ?? {};
      final storedHashes = await _loadStoredHashes();

      // Check if any file has changed hash.
      bool needsSync = false;
      for (final path in remoteFiles.keys) {
        final remoteHash = remoteFiles[path]?['hash'] as String?;
        final storedHash = storedHashes[path];
        if (remoteHash != storedHash) {
          needsSync = true;
          break;
        }
      }

      if (!needsSync) {
        if (kDebugMode) debugPrint('[Cache] syncIfNeeded: up-to-date, no downloads');
        return SyncResult.upToDate;
      }

      final filesToDownload = remoteFiles.entries
          .where((e) => e.value['hash'] != storedHashes[e.key])
          .map((e) => e.key)
          .toList();

      if (kDebugMode) {
        debugPrint('[Cache] syncIfNeeded: downloading ${filesToDownload.length} file(s)');
      }

      // Download in batches of _maxConcurrent to avoid hammering B2.
      // On failure of any single file, skip it (don't abort the whole batch).
      for (var i = 0; i < filesToDownload.length; i += _maxConcurrent) {
        final batch = filesToDownload.skip(i).take(_maxConcurrent).toList();
        await Future.wait(
          batch.map((path) async {
            try {
              await _fetchAndSave(path);
              // Bust memory cache for updated file.
              _memCache.remove(path);
            } catch (e) {
              if (kDebugMode) debugPrint('[Cache] sync failed for $path: $e');
            }
          }),
        );
      }

      // Update stored hashes and data_version.
      final newHashes = <String, String>{};
      for (final path in remoteFiles.keys) {
        final hash = remoteFiles[path]?['hash'] as String?;
        if (hash != null) newHashes[path] = hash;
      }
      await _saveStoredHashes(newHashes);

      final dataVersion = manifest['data_version'] as String?;
      if (dataVersion != null) {
        await _prefs.setString(AppConstants.spDataVersion, dataVersion);
      }

      if (kDebugMode) debugPrint('[Cache] syncIfNeeded: done');
      return SyncResult.updated;
    } catch (e) {
      // Network unavailable or server error — proceed with stale cache.
      if (kDebugMode) debugPrint('[Cache] syncIfNeeded: failed — $e');
      return SyncResult.failed;
    }
  }

  // ── Runtime read ───────────────────────────────────────────────────────────

  /// Returns the parsed JSON for [relativePath].
  ///
  /// [relativePath] examples:
  ///   `'data/calendar/2026_04.json'`
  ///   `'data/events/events.json'`
  ///
  /// Priority:
  ///   1. In-memory cache (zero-cost Map lookup — prevents re-parsing on rebuild).
  ///   2. Local disk/web cache (fast, offline-ready after first sync).
  ///   3. Remote CDN fetch + save (on cache miss — lazy download).
  ///
  /// Throws [RemoteDataUnavailableException] when all three layers fail.
  Future<Map<String, dynamic>> getJson(String relativePath) async {
    // 1. In-memory — fastest, zero I/O.
    final mem = _memCache[relativePath];
    if (mem != null) {
      if (kDebugMode) debugPrint('[Cache] HIT  mem  $relativePath');
      return mem;
    }

    // 2. Disk / SharedPreferences.
    final cached = await _readLocal(relativePath);
    if (cached != null) {
      if (kDebugMode) debugPrint('[Cache] HIT  disk $relativePath');
      _memCache[relativePath] = cached;
      return cached;
    }

    // 3. Network fallback (cache miss — file not yet synced).
    if (kDebugMode) debugPrint('[Cache] MISS net  $relativePath');
    try {
      await _fetchAndSave(relativePath);
      final afterFetch = await _readLocal(relativePath);
      if (afterFetch != null) {
        _memCache[relativePath] = afterFetch;
        return afterFetch;
      }
    } catch (e) {
      throw RemoteDataUnavailableException(relativePath, e);
    }

    throw RemoteDataUnavailableException(relativePath, 'fetch returned empty');
  }

  // ── Cache management ───────────────────────────────────────────────────────

  /// Wipes all cached JSON (memory + disk) and resets stored version/hashes.
  /// Next [syncIfNeeded] will re-download everything.
  Future<void> clearCache() async {
    _memCache.clear();
    if (kIsWeb) {
      final keysToRemove = _prefs
          .getKeys()
          .where((k) => k.startsWith(_webCachePrefix))
          .toList();
      for (final k in keysToRemove) {
        await _prefs.remove(k);
      }
    } else {
      await platform.clearCacheDir();
    }
    await _prefs.remove(AppConstants.spDataVersion);
    await _prefs.remove(AppConstants.spFileHashes);
  }

  /// Approximate total size of the JSON cache in bytes.
  Future<int> cacheSize() async {
    if (kIsWeb) {
      int total = 0;
      for (final key in _prefs.getKeys()) {
        if (key.startsWith(_webCachePrefix)) {
          total += (_prefs.getString(key) ?? '').length;
        }
      }
      return total;
    }
    return platform.cacheSizeBytes();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Fetch and parse manifest.json from the CDN.
  /// Updated: manifest-based sync
  Future<Map<String, dynamic>> _fetchManifest() async {
    final response = await _client
        .get(Uri.parse(AppConstants.manifestUrl))
        .timeout(_versionTimeout);
    if (response.statusCode != 200) {
      throw Exception('manifest.json: HTTP ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Load stored file hashes from SharedPreferences.
  /// Returns a map of {path: hash} for all previously downloaded files.
  Future<Map<String, String>> _loadStoredHashes() async {
    final raw = _prefs.getString(AppConstants.spFileHashes);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.cast<String, String>();
    } catch (_) {
      return {};
    }
  }

  /// Save file hashes to SharedPreferences.
  Future<void> _saveStoredHashes(Map<String, String> hashes) async {
    await _prefs.setString(AppConstants.spFileHashes, jsonEncode(hashes));
  }

  Future<void> _fetchAndSave(String relativePath) async {
    final url      = '${AppConstants.cdnBaseUrl}/$relativePath';
    final response = await _client
        .get(Uri.parse(url))
        .timeout(_fileTimeout);
    if (response.statusCode != 200) {
      throw Exception('$relativePath: HTTP ${response.statusCode}');
    }
    await _writeLocal(relativePath, response.body);
  }

  /// Read a cached JSON string and parse it.  Returns null on cache miss.
  Future<Map<String, dynamic>?> _readLocal(String relativePath) async {
    if (kIsWeb) {
      final raw = _prefs.getString(_webKey(relativePath));
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    }
    return platform.readFile(relativePath);
  }

  /// Write [body] (raw JSON string) to local cache.
  Future<void> _writeLocal(String relativePath, String body) async {
    if (kIsWeb) {
      await _prefs.setString(_webKey(relativePath), body);
    } else {
      await platform.writeFile(relativePath, body);
    }
  }

  /// SharedPreferences key for web cache.
  String _webKey(String relativePath) =>
      '$_webCachePrefix${relativePath.replaceAll('/', '_')}';
}

// ── Exception ──────────────────────────────────────────────────────────────

/// Thrown by [RemoteDataCache.getJson] when a file is not in the local cache
/// and cannot be fetched from the CDN (e.g. no internet on first launch).
class RemoteDataUnavailableException implements Exception {
  final String path;
  final Object cause;
  const RemoteDataUnavailableException(this.path, this.cause);

  @override
  String toString() =>
      'RemoteDataUnavailableException: $path — $cause\n'
      'Make sure the app has internet access on first launch to download data.';
}

// ── Riverpod provider ──────────────────────────────────────────────────────

final remoteDataCacheProvider = Provider<RemoteDataCache>((ref) {
  final prefs  = ref.watch(sharedPreferencesProvider);
  final client = http.Client();
  ref.onDispose(client.close);
  return RemoteDataCache(client, prefs);
});
