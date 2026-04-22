/// A calendar event the user has personally created.
///
/// Distinct from the app's built-in community events.
/// Lives entirely in local SharedPreferences — no login required.
class UserEventEntity {
  final String id;
  final String title;
  final String content;
  /// Gregorian date in 'YYYY-MM-DD' format.
  final String dateKey;
  /// Time of day as 'HH:mm', e.g. '09:00'.
  final String timeOfDay;
  final int lunarDay;
  /// Human-readable tibetan date label, e.g. "Day 25 · Month 3".
  final String lunarLabel;
  /// CDN image key (set when the event originates from app data).
  /// Null for user-created events → show default pagoda image.
  final String? imageKey;
  /// 'never' | 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String repeatType;
  /// Minutes before the event to fire the reminder. -1 = no reminder.
  final int reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEventEntity({
    required this.id,
    required this.title,
    this.content = '',
    required this.dateKey,
    this.timeOfDay = '09:00',
    this.lunarDay = 0,
    this.lunarLabel = '',
    this.imageKey,
    this.repeatType = 'never',
    this.reminderMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasReminder => reminderMinutes >= 0;

  UserEventEntity copyWith({
    String? title,
    String? content,
    String? dateKey,
    String? timeOfDay,
    int? lunarDay,
    String? lunarLabel,
    String? imageKey,
    String? repeatType,
    int? reminderMinutes,
    DateTime? updatedAt,
  }) =>
      UserEventEntity(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        dateKey: dateKey ?? this.dateKey,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        lunarDay: lunarDay ?? this.lunarDay,
        lunarLabel: lunarLabel ?? this.lunarLabel,
        imageKey: imageKey ?? this.imageKey,
        repeatType: repeatType ?? this.repeatType,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
