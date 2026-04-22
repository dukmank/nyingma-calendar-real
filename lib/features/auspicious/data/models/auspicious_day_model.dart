import '../../domain/entities/auspicious_day_entity.dart';

/// Parses one entry from `data/auspicious/auspicious.json → auspicious_days[]`.
///
/// This is a REFERENCE TABLE of recurring auspicious Tibetan lunar days —
/// NOT a per-calendar-date index.
///
/// Actual JSON structure:
/// {
///   "month_en": "all",
///   "month_bo": "all",
///   "day_en": "8",
///   "day_bo": "༨",
///   "name_en": "Medicine Buddha Day",
///   "name_bo": "སངས་རྒྱས་སྨན་ལྷའི་ཉིན་མོ།",
///   "short_description_en": "...",
///   "short_description_bo": "..."
/// }
class AuspiciousDayModel extends AuspiciousDayEntity {
  /// Tibetan lunar day number (e.g. "8", "10", "15")
  final String tibetanDayNumber;
  final String tibetanDayNumberBo;

  const AuspiciousDayModel({
    required super.titleEn,
    required super.titleBo,
    super.descriptionEn,
    super.descriptionBo,
    super.isMajor,
    // AuspiciousDayEntity fields we don't use from this JSON
    super.dateKey = '',
    super.imageKey,
    this.tibetanDayNumber = '',
    this.tibetanDayNumberBo = '',
  });

  factory AuspiciousDayModel.fromJson(Map<String, dynamic> json) {
    final dayEn = json['day_en'] as String? ?? '';
    final nameEn = json['name_en'] as String? ?? '';
    return AuspiciousDayModel(
      titleEn:          nameEn,
      titleBo:          json['name_bo'] as String? ?? '',
      descriptionEn:    json['short_description_en'] as String?,
      descriptionBo:    json['short_description_bo'] as String?,
      isMajor:          _isMajorDay(dayEn, nameEn),
      tibetanDayNumber:   dayEn,
      tibetanDayNumberBo: json['day_bo'] as String? ?? '',
    );
  }

  /// Major days: full moon (15), new moon (30), Guru Rinpoche (10),
  /// Medicine Buddha (8), Dakini (25), Dharma Protector (29)
  static bool _isMajorDay(String dayEn, String nameEn) {
    const majorDays = {'8', '10', '15', '25', '29', '30'};
    if (majorDays.contains(dayEn)) return true;
    final lowerName = nameEn.toLowerCase();
    return lowerName.contains('losar') || lowerName.contains('new year');
  }
}
