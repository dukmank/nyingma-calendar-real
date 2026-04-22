import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/auspicious')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/news')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(RouteNames.calendar);
      case 1: context.go(RouteNames.auspicious);
      case 2: context.go(RouteNames.events);
      case 3: context.go(RouteNames.news);
      case 4: context.go(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      // Persistent search FAB visible on all tabs
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'search_fab',
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textSecondary,
        elevation: 2,
        onPressed: () => context.push(RouteNames.search),
        tooltip: bo ? 'བཙལ།' : 'Search',
        child: const Icon(Icons.search, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: _AppBottomNav(
        currentIndex: currentIndex,
        bo: bo,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool bo;
  final ValueChanged<int> onTap;

  const _AppBottomNav({
    required this.currentIndex,
    required this.bo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.calendar_month_outlined, iconActive: Icons.calendar_month,
                  label: bo ? 'ལོ་ཐོ།' : 'CALENDAR', isActive: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.auto_awesome_outlined, iconActive: Icons.auto_awesome,
                  label: bo ? 'བཀྲ་ཤིས།' : 'AUSPICIOUS', isActive: currentIndex == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.event_outlined, iconActive: Icons.event,
                  label: bo ? 'དུས་ཆེན།' : 'EVENTS', isActive: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.newspaper_outlined, iconActive: Icons.newspaper,
                  label: bo ? 'གསར་འགྱུར།' : 'NEWS', isActive: currentIndex == 3, onTap: () => onTap(3)),
              _NavItem(icon: Icons.person_outline, iconActive: Icons.person,
                  label: bo ? 'རང་གི།' : 'PROFILE', isActive: currentIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconActive;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.iconActive,
    required this.label, required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? iconActive : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
