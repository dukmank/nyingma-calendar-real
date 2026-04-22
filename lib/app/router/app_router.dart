import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'route_names.dart';
import '../../core/constants/app_constants.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/day_detail/presentation/screens/day_detail_screen.dart';
import '../../features/astrology/presentation/screens/astrology_detail_screen.dart';
import '../../features/auspicious/presentation/screens/auspicious_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/my_practices_screen.dart';
import '../../features/profile/presentation/screens/my_events_screen.dart';
import '../../features/create_event/presentation/screens/create_event_screen.dart';
import '../../features/create_practice/presentation/screens/create_practice_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/news/presentation/screens/news_screen.dart';
import '../../features/news/presentation/screens/news_detail_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.calendar, // overridden by redirect below
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(AppConstants.spOnboardingDone) ?? false;
      final isOnboarding = state.matchedLocation == RouteNames.onboarding;
      if (!done && !isOnboarding) return RouteNames.onboarding;
      if (done && isOnboarding) return RouteNames.calendar;
      return null;
    },
    routes: [
      // Onboarding (full-screen, outside shell)
      GoRoute(
        path: RouteNames.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Shell route — bottom nav wrapper
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: RouteNames.calendar,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.auspicious,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AuspiciousScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.events,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EventsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.news,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NewsScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: RouteNames.dayDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final dateKey = state.pathParameters['dateKey'] ?? '';
          return DayDetailScreen(dateKey: dateKey);
        },
      ),
      GoRoute(
        path: RouteNames.astrologyDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';
          return AstrologyDetailScreen(astrologyKey: key);
        },
      ),
      GoRoute(
        path: RouteNames.eventDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: RouteNames.myPractices,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyPracticesScreen(),
      ),
      GoRoute(
        path: RouteNames.myEvents,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyEventsScreen(),
      ),
      GoRoute(
        path: RouteNames.createEvent,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: RouteNames.createPractice,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePracticeScreen(),
      ),
      GoRoute(
        path: RouteNames.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.newsDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return NewsDetailScreen(newsId: id);
        },
      ),
    ],
  );
}
