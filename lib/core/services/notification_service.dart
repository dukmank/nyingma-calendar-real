import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Simple wrapper around flutter_local_notifications.
///
/// On **web**, all methods are no-ops (the package doesn't support web).
/// On **Android / iOS**, schedules real local notifications.
///
/// Platform notes:
/// - Android 12 (API 31-32): requires SCHEDULE_EXACT_ALARM user permission.
///   If not granted, scheduling gracefully falls back to inexact.
/// - Android 13+ (API 33+): USE_EXACT_ALARM is declared in manifest —
///   no user approval needed for calendar-type apps.
/// - iOS 10+: permission is requested at init or on first schedule.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Notification channel IDs ─────────────────────────────────────────────

  static const _kRemindersChannelId   = 'nmc_reminders';
  static const _kRemindersChannelName = 'Event Reminders';
  static const _kPracticesChannelId   = 'nmc_practices';
  static const _kPracticesChannelName = 'Daily Practice Reminders';

  // ── Init (call once from bootstrap) ──────────────────────────────────────

  static Future<void> init() async {
    if (kIsWeb) return;

    // ── Timezone setup ────────────────────────────────────────────────────
    // Derive timezone from UTC offset (no external package needed).
    // Note: offset-based zones (Etc/GMT±X) don't track DST, so notifications
    // may be off by 1 hour twice/year during DST transitions — acceptable
    // for a calendar app. Etc/GMT uses inverted sign: GMT-7 = UTC+7.
    tz.initializeTimeZones();
    try {
      final offset = DateTime.now().timeZoneOffset;
      final h = offset.inHours;
      // Etc/GMT sign is inverted (POSIX convention): Etc/GMT-7 = UTC+7
      final zoneName = h == 0 ? 'UTC' : 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}';
      tz.setLocalLocation(tz.getLocation(zoneName));
      debugPrint('NotificationService: timezone set to $zoneName (offset $offset)');
    } catch (e) {
      debugPrint('NotificationService: timezone lookup failed: $e — using UTC');
      tz.setLocalLocation(tz.UTC);
    }

    // ── Android init ──────────────────────────────────────────────────────
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── iOS / macOS init ──────────────────────────────────────────────────
    // Request permissions at init time so the user sees the prompt early.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // ask explicitly via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Handle notifications tapped while app is in foreground (iOS 10+)
      notificationCategories: [],
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: darwinSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    // ── Create Android notification channels (required API 26+) ──────────
    await _createAndroidChannels();

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse details) {
    debugPrint('Notification tapped: id=${details.id} payload=${details.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse details) {
    debugPrint('Background notification tapped: id=${details.id}');
  }

  static Future<void> _createAndroidChannels() async {
    if (kIsWeb) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _kRemindersChannelId,
      _kRemindersChannelName,
      description: 'Reminders for events and auspicious days',
      importance: Importance.high,
      playSound: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _kPracticesChannelId,
      _kPracticesChannelName,
      description: 'Daily reminders for spiritual practices',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
  }

  // ── Permission ────────────────────────────────────────────────────────────

  /// Request notification permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    if (kIsWeb || !_initialized) return false;

    // Android 13+ (API 33)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS — use the iOS-specific implementation
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // ── One-time notification ─────────────────────────────────────────────────

  /// Schedule a one-time notification at [scheduledTime] (device local time).
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (kIsWeb || !_initialized) return;
    if (scheduledTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      _kRemindersChannelId,
      _kRemindersChannelName,
      channelDescription: 'Reminders for events and auspicious days',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _scheduleZoned(
      id: id,
      title: title,
      body: body,
      tzTime: tzTime,
      details: details,
      payload: payload,
    );
  }

  // ── Daily practice reminder ───────────────────────────────────────────────

  /// Schedule a repeating daily notification at [hour]:[minute] local time.
  static Future<void> scheduleDailyPractice({
    required int id,
    required String practiceName,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || !_initialized) return;

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));

    final androidDetails = AndroidNotificationDetails(
      _kPracticesChannelId,
      _kPracticesChannelName,
      channelDescription: 'Daily reminders for spiritual practices',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    final tzTime = tz.TZDateTime.from(next, tz.local);

    await _scheduleZoned(
      id: id,
      title: '🙏 Practice Reminder',
      body: practiceName,
      tzTime: tzTime,
      details: details,
      matchComponents: DateTimeComponents.time, // repeat daily
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Derive a stable int id from a string key (practice id, event id, etc.)
  static int idFromString(String key) => key.hashCode.abs() % 2147483647;

  /// Schedules with `exactAllowWhileIdle` on API 33+ or approved API 31-32;
  /// gracefully falls back to `inexactAllowWhileIdle` if exact alarms are
  /// not permitted (common on unconfigured Android 12 devices).
  static Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime tzTime,
    required NotificationDetails details,
    String? payload,
    DateTimeComponents? matchComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        payload: payload,
        matchDateTimeComponents: matchComponents,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationService: scheduled #$id (exact) at $tzTime');
    } catch (e) {
      // Exact alarms not permitted — fall back to inexact
      debugPrint('NotificationService: exact alarm failed ($e) — falling back to inexact');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          details,
          payload: payload,
          matchDateTimeComponents: matchComponents,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('NotificationService: scheduled #$id (inexact) at $tzTime');
      } catch (e2) {
        debugPrint('NotificationService: scheduling failed entirely: $e2');
      }
    }
  }
}
