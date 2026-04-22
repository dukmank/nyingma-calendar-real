import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Singleton image cache manager used by [AppNetworkImage] and
/// [FullScreenImageViewer].
///
/// Why a custom manager?
/// B2's default response header is `Cache-Control: max-age=3600` (1 hour).
/// flutter_cache_manager respects that header and re-downloads images every
/// hour even if they haven't changed — which wastes bandwidth during testing.
///
/// This manager overrides [stalePeriod] to 30 days so images are kept locally
/// and not re-fetched until the content actually changes.
class AppCacheManager {
  AppCacheManager._();

  static const String _key = 'nyingmapaImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 300,
      fileService: HttpFileService(),
    ),
  );
}
