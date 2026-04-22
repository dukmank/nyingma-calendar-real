import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/remote_data_cache.dart';
import '../core/theme/app_theme.dart';

// ── Sync provider ──────────────────────────────────────────────────────────

/// Runs [RemoteDataCache.syncIfNeeded] exactly once per app lifecycle.
///
/// • If local version == remote version: resolves instantly (no downloads).
/// • If new version: downloads all files, then resolves.
/// • If network fails: resolves anyway (stale cache is fine).
final appSyncProvider = FutureProvider<SyncResult>((ref) {
  return ref.read(remoteDataCacheProvider).syncIfNeeded();
});

// ── Wrapper widget ─────────────────────────────────────────────────────────

/// Wraps the root app widget.
/// Shows a minimal loading screen while [appSyncProvider] is running,
/// then reveals [child] whether the sync succeeded or failed.
class AppInitWrapper extends ConsumerWidget {
  final Widget child;

  const AppInitWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(appSyncProvider);

    return sync.when(
      // Sync done (or failed gracefully) — show the real app.
      data:  (_) => child,
      error: (_, __) => child,

      // Sync in progress — show a branded splash screen.
      loading: () => const _SyncSplash(),
    );
  }
}

// ── Splash screen shown while syncing ──────────────────────────────────────

class _SyncSplash extends StatelessWidget {
  const _SyncSplash();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 72,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Updating calendar data…',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
