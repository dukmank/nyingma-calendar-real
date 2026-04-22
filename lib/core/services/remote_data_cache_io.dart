/// dart:io-based file cache helpers.
/// Used on Android, iOS, macOS, Linux, and Windows.
/// On web this file is replaced by remote_data_cache_web.dart via a
/// conditional import in remote_data_cache.dart.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

const String _cacheDirName = 'nmc_data_cache';

Future<Directory> _cacheDir() async {
  final base = await getApplicationDocumentsDirectory();
  return Directory('${base.path}/$_cacheDirName');
}

/// Converts `data/calendar/2026_04.json` → `{cacheDir}/data_calendar_2026_04.json`
Future<File> _localFileFor(String relativePath) async {
  final dir  = await _cacheDir();
  await dir.create(recursive: true);
  final name = relativePath.replaceAll('/', '_');
  return File('${dir.path}/$name');
}

/// Read cached JSON file. Returns null on cache miss.
Future<Map<String, dynamic>?> readFile(String relativePath) async {
  final file = await _localFileFor(relativePath);
  if (!await file.exists()) return null;
  final raw = await file.readAsString();
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// Write raw JSON string to local cache file.
Future<void> writeFile(String relativePath, String body) async {
  final file = await _localFileFor(relativePath);
  await file.writeAsString(body, flush: true);
}

/// Delete the entire cache directory.
Future<void> clearCacheDir() async {
  final dir = await _cacheDir();
  if (await dir.exists()) await dir.delete(recursive: true);
}

/// Total size of cached files in bytes.
Future<int> cacheSizeBytes() async {
  final dir = await _cacheDir();
  if (!await dir.exists()) return 0;
  int total = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) total += await entity.length();
  }
  return total;
}
