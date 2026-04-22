import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';

// ── Data model for upcoming auspicious days ──────────────────────────────────

class AuspiciousDay {
  final String   dateKey;
  final DateTime date;
  final String   nameEn;
  final String   nameBo;
  final String?  imageKey;
  final String   tibetanDayEn;
  final String   tibetanMonthEn;
  final String   descEn;
  final String   descBo;

  const AuspiciousDay({
    required this.dateKey,
    required this.date,
    required this.nameEn,
    required this.nameBo,
    this.imageKey,
    required this.tibetanDayEn,
    required this.tibetanMonthEn,
    required this.descEn,
    required this.descBo,
  });
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Loads upcoming auspicious days from B2:
///   1. `data/reference/auspicious_days_ref.json` — description lookup table
///   2. `data/calendar/YYYY_MM.json`              — 6 months of calendar days
/// Returns a date-sorted list of future auspicious days.
final auspiciousProvider = FutureProvider<List<AuspiciousDay>>((ref) async {
  final cache = ref.watch(remoteDataCacheProvider);
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // ── 1. Load description lookup (auspicious_days_ref.json → types[]) ──────
  final Map<String, String> descEnMap = {};
  final Map<String, String> descBoMap = {};
  try {
    final decoded = await cache.getJson(AppConstants.auspiciousPath);
    final rawList = decoded['types'];               // field: types[]
    if (rawList is List) {
      for (final item in rawList) {
        if (item is! Map) continue;
        // key field is auspicious_day_name_en (e.g. "Medicine Buddha Day")
        final nameRaw = (item['auspicious_day_name_en'] as String? ?? '').toLowerCase().trim();
        if (nameRaw.isEmpty) continue;
        final descEn = item['short_description_en'] as String? ?? '';
        final descBo = item['short_description_bo'] as String? ?? '';
        descEnMap[nameRaw] = descEn;
        descBoMap[nameRaw] = descBo;
        // Also index without " day" suffix for loose matching
        if (nameRaw.endsWith(' day')) {
          final withoutDay = nameRaw.substring(0, nameRaw.length - 4).trim();
          descEnMap.putIfAbsent(withoutDay, () => descEn);
          descBoMap.putIfAbsent(withoutDay, () => descBo);
        }
      }
    }
  } catch (e) {
    debugPrint('auspiciousProvider: desc load failed — $e');
  }

  // ── 2. Load 6 months of calendar data ─────────────────────────────────────
  final all = <AuspiciousDay>[];
  for (var offset = 0; offset <= 5; offset++) {
    var y = now.year;
    var m = now.month + offset;
    while (m > 12) { m -= 12; y++; }
    try {
      final calJson  = await cache.getJson(AppConstants.calendarPath(y, m));
      final rawDays  = calJson['days'];
      if (rawDays is! List) continue;
      for (final item in rawDays) {
        if (item is! Map) continue;
        final nameEn = item['auspicious_day_name_en'] as String?;
        if (nameEn == null || nameEn.isEmpty) continue;
        final dateKey = item['date_key'] as String? ?? '';
        if (dateKey.isEmpty) continue;
        final parts = dateKey.split('-');
        if (parts.length != 3) continue;
        final dt = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (dt.isBefore(today)) continue;

        final nameLower = nameEn.toLowerCase().trim();
        all.add(AuspiciousDay(
          dateKey:        dateKey,
          date:           dt,
          nameEn:         nameEn,
          nameBo:         item['auspicious_day_name_bo'] as String? ?? nameEn,
          imageKey:       item['image_key'] as String?,
          tibetanDayEn:   item['tibetan_day_en']   as String? ?? '',
          tibetanMonthEn: item['tibetan_month_en']  as String? ?? '',
          descEn:         descEnMap[nameLower]   ?? '',
          descBo:         descBoMap[nameLower]   ?? '',
        ));
      }
    } catch (e) {
      debugPrint('auspiciousProvider: month $y-$m load failed — $e');
    }
  }

  // Return ALL upcoming auspicious days sorted by date.
  // The screen will group by type based on the user-selected date.
  all.sort((a, b) => a.date.compareTo(b.date));
  return all;
});
