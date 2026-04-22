import '../../domain/entities/calendar_day_entity.dart';

// ── Month helpers ──────────────────────────────────────────────────────────────

const _monthStrToLabel = {
  'JAN': 'January', 'FEB': 'February', 'MAR': 'March', 'APR': 'April',
  'MAY': 'May', 'JUN': 'June', 'JUL': 'July', 'AUG': 'August',
  'SEP': 'September', 'OCT': 'October', 'NOV': 'November', 'DEC': 'December',
};

/// Major Tibetan auspicious day names — used to derive isExtremelyAuspicious
/// from the flat `auspicious_day_name_en` field in the monthly calendar.
const _majorAuspiciousNames = {
  'losar', 'new year', 'full moon', 'medicine buddha',
  'guru rinpoche', 'dakini', 'nyungne', 'parinirvana',
};

bool _isMajorByName(String? name) {
  if (name == null || name.isEmpty) return false;
  final lower = name.toLowerCase();
  return _majorAuspiciousNames.any((k) => lower.contains(k));
}

class CalendarDayModel extends CalendarDayEntity {
  const CalendarDayModel({
    required super.dateKey,
    required super.day,
    required super.month,
    required super.year,
    super.weekdayEn,
    super.weekdayBo,
    super.tibetanDay,
    super.tibetanDayEn,
    super.tibetanMonth,
    super.tibetanYear,
    super.isToday,
    super.isSelected,
    super.hasEvents,
    super.hasAstrology,
    super.isAuspicious,
    super.isInauspicious,
    super.isExtremelyAuspicious,
  });

  /// Parses one day entry from the monthly calendar JSON.
  ///
  /// Monthly calendar day schema (FLAT — no nested gregorian/tibetan):
  /// {
  ///   "date_key": "2026-04-03",
  ///   "gregorian_date": 3,
  ///   "gregorian_date_bo": "༣",
  ///   "weekday_en": "Friday",
  ///   "weekday_bo": "...",
  ///   "tibetan_day_en": "17",
  ///   "tibetan_day_bo": "༡༧",
  ///   "tibetan_month_en": "2",
  ///   "tibetan_month_bo": "༢༽",
  ///   "tibetan_month_name_en": "Wo-Dawa",
  ///   "tibetan_month_name_bo": "...",
  ///   "tibetan_year_en": "2153",
  ///   "tibetan_year_bo": "༢༡༥༣",
  ///   "animal_month_en": "Snake",
  ///   "animal_month_bo": "...",
  ///   "lunar_status_en": null,
  ///   "image_key": null,
  ///   "auspicious_day_name_en": null,   ← string or null
  ///   "auspicious_day_name_bo": null,
  ///   "astrology_status": {"naga_day": "avoid", "flag_day": "auspicious", ...},
  ///   "has_event": false
  /// }
  ///
  /// [monthInt] — Gregorian month number (1–12) from the parent monthly JSON.
  /// [yearInt]  — Gregorian year from the parent monthly JSON.
  factory CalendarDayModel.fromJson(
      Map<String, dynamic> json, int monthInt, int yearInt) {
    final dateKey = json['date_key'] as String? ?? '';

    final today    = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Auspicious day
    final auspName = json['auspicious_day_name_en'] as String?;
    final isAuspicious = auspName != null && auspName.isNotEmpty;
    final isExtremelyAuspicious = _isMajorByName(auspName);

    // Astrology status map
    final astrologyStatus = json['astrology_status'] as Map<String, dynamic>?;
    final hasAstrology    = astrologyStatus != null && astrologyStatus.isNotEmpty;
    // isInauspicious: specifically inauspicious_day == 'caution' in astrology_status
    final isInauspicious  = astrologyStatus?['inauspicious_day'] == 'caution';

    return CalendarDayModel(
      dateKey:               dateKey,
      day:                   int.tryParse(json['gregorian_date']?.toString() ?? '') ?? 1,
      month:                 monthInt,
      year:                  yearInt,
      weekdayEn:             json['weekday_en'] as String?,
      weekdayBo:             json['weekday_bo'] as String?,
      tibetanDay:            json['tibetan_day_bo']  as String?,   // Tibetan script "༢༨"
      tibetanDayEn:          json['tibetan_day_en']  as String?,   // Arabic string  "28"
      tibetanMonth:          json['tibetan_month_bo'] as String?,
      tibetanYear:           json['tibetan_year_bo']  as String?,
      isToday:               dateKey == todayKey,
      hasEvents:             json['has_event'] as bool? ?? false,
      hasAstrology:          hasAstrology,
      isAuspicious:          isAuspicious,
      isInauspicious:        isInauspicious,
      isExtremelyAuspicious: isExtremelyAuspicious,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CalendarMonthModel {
  final int year;
  final int month;
  final String monthLabelEn;
  final String tibetanMonthEn;
  final String tibetanMonthBo;
  final String yearLabelEn;
  final String yearLabelBo;
  final String yearNameEn;   // e.g. "Fire Horse"
  final String yearNameBo;   // e.g. "མེ།རྟ།"
  final List<CalendarDayModel> days;

  const CalendarMonthModel({
    required this.year,
    required this.month,
    required this.monthLabelEn,
    required this.tibetanMonthEn,
    required this.tibetanMonthBo,
    required this.yearLabelEn,
    required this.yearLabelBo,
    this.yearNameEn = '',
    this.yearNameBo = '',
    required this.days,
  });

  /// Parses the monthly calendar JSON file.
  ///
  /// Top-level schema:
  /// {
  ///   "year": 2026,
  ///   "month": 4,
  ///   "gregorian_month_en": "APR",
  ///   "gregorian_month_bo": "...",
  ///   "days": [...]
  /// }
  factory CalendarMonthModel.fromJson(Map<String, dynamic> json) {
    final year     = json['year'] as int;
    final month    = json['month'] as int;
    final monthStr = json['gregorian_month_en'] as String? ?? 'JAN';

    // Tibetan month label: from first day in the array
    String tibetanMonthEn = '';
    String tibetanMonthBo = '';
    final daysList = (json['days'] as List?) ?? [];
    if (daysList.isNotEmpty) {
      final first = daysList.first as Map<String, dynamic>;
      tibetanMonthEn = first['tibetan_month_name_en'] as String? ?? '';
      tibetanMonthBo = first['tibetan_month_name_bo'] as String? ?? '';
    }

    return CalendarMonthModel(
      year:           year,
      month:          month,
      monthLabelEn:   _monthStrToLabel[monthStr] ?? monthStr,
      tibetanMonthEn: tibetanMonthEn,
      tibetanMonthBo: tibetanMonthBo,
      yearLabelEn:    year.toString(),
      yearLabelBo:    '',
      yearNameEn:     json['year_name_en'] as String? ?? '',
      yearNameBo:     json['year_name_bo'] as String? ?? '',
      days: daysList
          .map((d) => CalendarDayModel.fromJson(
                d as Map<String, dynamic>, month, year))
          .toList(),
    );
  }
}
