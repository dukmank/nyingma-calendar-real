/// A user-defined daily spiritual practice (e.g. Ngöndro, Morning Sadhana).
///
/// [completionDates] is the source of truth — a list of 'YYYY-MM-DD' strings
/// recording every day this practice was marked as done. All derived fields
/// ([isDoneToday], [streak]) are computed from it rather than stored
/// separately, so the local and remote state always stay in sync.
class PracticeEntity {
  final String id;
  final String title;
  final String? description;
  /// Hex colour string, e.g. '#8B1A1A'. Stored as a string so it round-trips
  /// through JSON without needing the Flutter SDK in the domain layer.
  final String colorHex;
  /// Ordered list (ascending) of 'YYYY-MM-DD' strings.
  final List<String> completionDates;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PracticeEntity({
    required this.id,
    required this.title,
    this.description,
    this.colorHex = '#8B1A1A',
    this.completionDates = const [],
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed fields ───────────────────────────────────────────────────────

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  bool get isDoneToday => completionDates.contains(_todayKey);

  /// Number of consecutive days this practice was completed up to and
  /// including today (or yesterday, if today hasn't been marked yet).
  int get streak {
    if (completionDates.isEmpty) return 0;
    final dateSet = completionDates.toSet();
    var current = DateTime.now();
    // If not done today, start counting from yesterday so the streak
    // persists until midnight.
    if (!dateSet.contains(_todayKey)) {
      current = current.subtract(const Duration(days: 1));
    }
    int count = 0;
    while (true) {
      final key =
          '${current.year}-${current.month.toString().padLeft(2,'0')}-${current.day.toString().padLeft(2,'0')}';
      if (!dateSet.contains(key)) break;
      count++;
      current = current.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ── Mutation helpers ──────────────────────────────────────────────────────

  PracticeEntity copyWith({
    String? title,
    String? description,
    String? colorHex,
    List<String>? completionDates,
    int? sortOrder,
    DateTime? updatedAt,
  }) =>
      PracticeEntity(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        colorHex: colorHex ?? this.colorHex,
        completionDates: completionDates ?? this.completionDates,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// Returns a new entity with today's date added to (or removed from)
  /// [completionDates].
  PracticeEntity withTodayToggled() {
    final today = _todayKey;
    final dates = List<String>.from(completionDates);
    if (dates.contains(today)) {
      dates.remove(today);
    } else {
      dates.add(today);
      dates.sort();
    }
    return copyWith(completionDates: dates);
  }
}
