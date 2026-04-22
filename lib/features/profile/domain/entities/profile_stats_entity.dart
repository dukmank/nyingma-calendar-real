/// Aggregate statistics computed from practices and events.
///
/// Derived — never stored directly; always recalculated from the source data
/// so there's no chance of stale counts.
class ProfileStatsEntity {
  /// Events saved during the current calendar month.
  final int eventsThisMonth;
  /// Total practice completions this calendar month (across all practices).
  final int practicesThisMonth;
  /// Current consecutive-day streak across all active practices.
  final int currentStreak;
  /// All-time longest streak.
  final int longestStreak;
  /// Total unique days at least one practice was completed.
  final int totalDaysPracticed;

  const ProfileStatsEntity({
    this.eventsThisMonth = 0,
    this.practicesThisMonth = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalDaysPracticed = 0,
  });

  /// Compute stats from live data.
  factory ProfileStatsEntity.compute({
    required List<dynamic> practices,   // List<PracticeEntity>
    required List<dynamic> events,      // List<UserEventEntity>
  }) {
    final now = DateTime.now();
    final monthPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Count practice completions this month
    int practicesThisMonth = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    final allDoneSet = <String>{};

    for (final p in practices) {
      final dates = (p.completionDates as List<String>);
      practicesThisMonth +=
          dates.where((d) => d.startsWith(monthPrefix)).length;
      allDoneSet.addAll(dates);
      final s = p.streak as int;
      if (s > currentStreak) currentStreak = s;
    }

    // Longest-ever streak: walk allDoneSet
    if (allDoneSet.isNotEmpty) {
      final sorted = allDoneSet.toList()..sort();
      int run = 1, maxRun = 1;
      for (int i = 1; i < sorted.length; i++) {
        final prev = DateTime.parse(sorted[i - 1]);
        final curr = DateTime.parse(sorted[i]);
        if (curr.difference(prev).inDays == 1) {
          run++;
          if (run > maxRun) maxRun = run;
        } else {
          run = 1;
        }
      }
      longestStreak = maxRun;
    }

    // Count events this month
    final eventsThisMonth = (events as List).where((e) {
      final dk = e.dateKey as String;
      return dk.startsWith(monthPrefix);
    }).length;

    return ProfileStatsEntity(
      eventsThisMonth: eventsThisMonth,
      practicesThisMonth: practicesThisMonth,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalDaysPracticed: allDoneSet.length,
    );
  }
}
