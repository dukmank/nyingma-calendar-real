import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_cache_manager.dart';

/// Full-screen interactive image viewer with pinch-to-zoom.
///
/// Open via [Navigator.of(context).push(MaterialPageRoute(...))]
/// or via [FullScreenImageViewer.open].
/// This is a proper full-screen page — NOT a dialog or popup.
class FullScreenImageViewer extends StatefulWidget {
  final String imageKey;

  /// Optional hero tag for shared-element transition.
  final String? heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageKey,
    this.heroTag,
  });

  /// Convenience helper to push this screen onto the navigator.
  static Future<void> open(
    BuildContext context, {
    required String imageKey,
    String? heroTag,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, animation, secondary) => FullScreenImageViewer(
          imageKey: imageKey,
          heroTag: heroTag,
        ),
        transitionsBuilder: (ctx, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transform = TransformationController();
  bool _showControls = true;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _resetZoom() => _transform.value = Matrix4.identity();

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _doubleTapZoom(TapDownDetails details) {
    final isIdentity = _transform.value == Matrix4.identity();
    if (isIdentity) {
      // Zoom into tapped location
      const scale = 2.5;
      final pos = details.localPosition;
      final x = -pos.dx * (scale - 1);
      final y = -pos.dy * (scale - 1);
      _transform.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
    } else {
      _resetZoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.imageUrl(widget.imageKey);

    Widget image = CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
        errorWidget: (_, __, ___) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: Colors.white30, size: 64),
              SizedBox(height: 12),
              Text('Image unavailable',
                  style: TextStyle(color: Colors.white30, fontSize: 13)),
            ],
          ),
        ),
      );

    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 22),
                ),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: _doubleTapZoom,
        onDoubleTap: () {}, // must be present for onDoubleTapDown to fire
        child: Center(
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.5,
            maxScale: 8.0,
            child: image,
          ),
        ),
      ),
    );
  }
}
