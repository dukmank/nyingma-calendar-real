import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'app_init.dart';
import 'router/app_router.dart';

class NyingmapaApp extends ConsumerWidget {
  const NyingmapaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppInitWrapper(
      child: MaterialApp.router(
        title: 'Nyingmapa Calendar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
