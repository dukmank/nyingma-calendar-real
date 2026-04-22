/// Web stub for dart:io cache helpers.
/// All JSON caching on web goes through SharedPreferences (handled directly
/// in RemoteDataCache via kIsWeb guards), so these functions are never called.
/// They exist only to satisfy the conditional-import contract.

Future<Map<String, dynamic>?> readFile(String relativePath) async => null;
Future<void> writeFile(String relativePath, String body) async {}
Future<void> clearCacheDir() async {}
Future<int> cacheSizeBytes() async => 0;
