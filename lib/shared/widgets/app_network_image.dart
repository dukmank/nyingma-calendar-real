import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_cache_manager.dart';
import '../../core/theme/app_theme.dart';

/// Loads a B2 image by [imageKey] with persistent local caching.
///
/// Uses [CachedNetworkImage] + [AppCacheManager] (30-day TTL) on ALL
/// platforms — mobile, desktop, and web.
///
/// On **web**, images are additionally cached by the B2 service worker
/// (`sw.js`) in Cache Storage for 30 days, overriding B2's default
/// `Cache-Control: max-age=3600`.  After the first download, every
/// subsequent page load serves images entirely from the local cache with
/// zero B2 bandwidth cost.
///
/// The widget is `const`-constructible so Flutter can skip rebuilds when
/// [imageKey] hasn't changed.
class AppNetworkImage extends StatelessWidget {
  final String imageKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.imageKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = AppConstants.imageUrl(imageKey);

    final image = CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _error(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.gold),
          ),
        ),
      );

  Widget _error() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.temple_buddhist_outlined,
              color: AppColors.gold, size: 28),
        ),
      );
}
