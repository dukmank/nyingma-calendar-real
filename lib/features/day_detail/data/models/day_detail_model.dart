import '../../domain/entities/day_detail_entity.dart';
import '../../domain/entities/gregorian_info.dart';
import '../../domain/entities/tibetan_info.dart';
import '../../domain/entities/astrology_status_entity.dart';
import '../../domain/entities/direction_entity.dart';

// ── Month helpers ──────────────────────────────────────────────────────────────

const _monthStrToInt = {
  'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
  'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
};

const _monthStrToLabel = {
  'JAN': 'January', 'FEB': 'February', 'MAR': 'March', 'APR': 'April',
  'MAY': 'May', 'JUN': 'June', 'JUL': 'July', 'AUG': 'August',
  'SEP': 'September', 'OCT': 'October', 'NOV': 'November', 'DEC': 'December',
};

// ── Human-readable label maps for all 8 astrology keys ────────────────────────

const _astrologyLabelEn = {
  'naga_day':         'Naga Day',
  'flag_day':         'Flag Day',
  'fire_ritual':      'Fire Ritual',
  'hair_cutting':     'Hair Cutting',
  'torma_offering':   'Torma Offering',
  'empty_vase':       'Empty Vase',
  'daily_restriction':'Daily Restriction',
  'auspicious_times': 'Auspicious Times',
};

const _astrologyLabelBo = {
  'naga_day':         'ཀླུ་ཐེབས།',
  'flag_day':         'རྒྱལ་མཚན་ཉིན།',
  'fire_ritual':      'མེ་མཆོད།',
  'hair_cutting':     'སྐྲ་གཅོད།',
  'torma_offering':   'གཏོར་མ།',
  'empty_vase':       'བུམ་སྟོང་།',
  'daily_restriction':'ཉིན་རེའི་ལྡོག་ཆ།',
  'auspicious_times': 'བཀྲ་ཤིས་ཆུ་ཚོད།',
};

// ── Model ──────────────────────────────────────────────────────────────────────

class DayDetailModel extends DayDetailEntity {
  /// Model-only: astrology items with full type information
  final List<AstrologyStatusModelItem> astrologyItems;

  /// Model-only: inline event objects from the day detail file.
  /// Schema: { name_en, name_bo, category_en, category_bo, details_en, details_bo, image_key }
  final List<Map<String, dynamic>> inlineEvents;

  /// Model-only: element description (English)
  final String? elementCombinationDescEn;

  /// Model-only: wisdom quote author (not in current JSON, reserved for future)
  final String? wisdomAuthor;

  /// Model-only: whether this Tibetan day is doubled in the month.
  /// Derived from tibetan.lunar_status_en containing "doubled".
  final bool tibetanDayDoubled;

  const DayDetailModel({
    required super.dateKey,
    required super.gregorian,
    required super.tibetan,
    super.title,
    super.titleBo,
    super.imageKey,
    super.significanceEn,
    super.significanceBo,
    super.wisdomEn,
    super.wisdomBo,
    super.elementCombination,
    super.elementCombinationBo,
    super.elementCombinationDescBo,
    super.astrology,
    super.directions,
    super.eventIds,
    this.astrologyItems = const [],
    this.inlineEvents = const [],
    this.elementCombinationDescEn,
    this.wisdomAuthor,
    this.tibetanDayDoubled = false,
  });

  // ── fromJson ──────────────────────────────────────────────────────────────────
  //
  // Day detail JSON schema:
  // {
  //   "date_key": "2026-04-03",
  //   "gregorian": { "year", "year_bo", "month_en", "month_bo", "date", "date_bo",
  //                  "weekday_en", "weekday_bo" },
  //   "tibetan":   { "year_en", "year_bo", "month_en", "month_bo",
  //                  "month_name_en", "month_name_bo", "animal_month_en",
  //                  "animal_month_bo", "day_en", "day_bo",
  //                  "lunar_status_en", "lunar_status_bo" },
  //   "significance": { "day_significance_en", "day_significance_bo",
  //                     "element_combo_en", "element_combo_bo",
  //                     "meaning_of_coincidence_en", "meaning_of_coincidence_bo" },
  //   "image_key": null | "losar",
  //   "auspicious_day": null | { "name_en", "name_bo", "short_description_en",
  //                               "short_description_bo" },
  //   "astrology_cards": [ { "type", "status_en", "status_bo",
  //                           "image_key", "popup_ref" }, ... ],
  //   "torma_offering":   { "direction_en", "direction_bo", "image_key", "popup_ref" },
  //   "empty_vase":       { "direction_en", "direction_bo", "image_key", "popup_ref" },
  //   "daily_restriction":{ "description_en", "description_bo", "image_key", "popup_ref" },
  //   "auspicious_times": { "description_en", "description_bo", "image_key", "popup_ref" },
  //   "events": [ { "name_en", "name_bo", "category_en", "category_bo",
  //                  "details_en", "details_bo", "image_key" }, ... ]
  // }

  factory DayDetailModel.fromJson(Map<String, dynamic> json) {
    final dateKey = json['date_key'] as String? ?? '';

    final greg = json['gregorian'] as Map<String, dynamic>? ?? {};
    final tib  = json['tibetan']  as Map<String, dynamic>? ?? {};
    final sig  = json['significance'] as Map<String, dynamic>?;

    final monthStr  = greg['month_en'] as String? ?? 'JAN';
    final monthInt  = _monthStrToInt[monthStr] ?? 1;

    // ── Build combined astrology list ────────────────────────────────────────
    // astrology_cards = list of { type, status_en, status_bo, image_key }
    final cards     = (json['astrology_cards'] as List?) ?? [];
    final astrologyItems = <AstrologyStatusModelItem>[];

    for (final card in cards) {
      final c       = card as Map<String, dynamic>;
      final key     = c['type'] as String? ?? '';
      final statusStr = c['status_en'] as String? ?? '';
      astrologyItems.add(AstrologyStatusModelItem(
        key:        key,
        labelEn:    _astrologyLabelEn[key] ?? key,
        labelBo:    _astrologyLabelBo[key] ?? '',
        status:     _parseStatus(statusStr),
        subLabelEn: statusStr,
        subLabelBo: c['status_bo'] as String?,
        iconKey:    c['image_key'] as String?,
      ));
    }

    // Separate top-level keys: torma_offering, empty_vase, daily_restriction, auspicious_times
    void _addSeparateKey(String key, Map<String, dynamic>? map) {
      if (map == null) return;
      final desc   = map['description_en'] as String?
          ?? map['direction_en'] as String?
          ?? '';
      final descBo = map['description_bo'] as String?
          ?? map['direction_bo'] as String?;
      astrologyItems.add(AstrologyStatusModelItem(
        key:        key,
        labelEn:    _astrologyLabelEn[key] ?? key,
        labelBo:    _astrologyLabelBo[key] ?? '',
        status:     AstrologyStatusType.neutral,
        subLabelEn: desc,
        subLabelBo: descBo,
        iconKey:    map['image_key'] as String?,
      ));
    }

    _addSeparateKey('torma_offering',   json['torma_offering']   as Map<String, dynamic>?);
    _addSeparateKey('empty_vase',       json['empty_vase']       as Map<String, dynamic>?);
    _addSeparateKey('daily_restriction',json['daily_restriction'] as Map<String, dynamic>?);
    _addSeparateKey('auspicious_times', json['auspicious_times'] as Map<String, dynamic>?);

    // ── Inline events ────────────────────────────────────────────────────────
    final eventsRaw   = (json['events'] as List?) ?? [];
    final inlineEvents = eventsRaw.cast<Map<String, dynamic>>();

    // ── Auspicious day ───────────────────────────────────────────────────────
    final auspMap = json['auspicious_day'] as Map<String, dynamic>?;

    // ── Tibetan day doubled flag ──────────────────────────────────────────────
    final lunarStatus = (tib['lunar_status_en'] as String? ?? '').toLowerCase();
    final tibetanDayDoubled = lunarStatus.contains('doubled');

    return DayDetailModel(
      dateKey: dateKey,

      gregorian: GregorianInfo(
        day:          greg['date'] as int? ?? 1,
        month:        monthInt,
        year:         greg['year'] as int? ?? 0,
        weekdayEn:    greg['weekday_en'] as String?,
        monthLabelEn: _monthStrToLabel[monthStr] ?? monthStr,
      ),

      tibetan: TibetanInfo(
        day:              tib['day_bo']           as String?,
        month:            tib['month_bo']         as String?,
        year:             tib['year_bo']          as String?,
        dayEn:            tib['day_en']?.toString(),
        monthEn:          tib['month_en']?.toString(),
        monthNameEn:      tib['month_name_en']    as String?,
        yearEn:           tib['year_en']?.toString(),
        yearNameEn:       json['tibetan_year_name_en'] as String?
                          ?? tib['year_name_en']  as String?,
        animalMonthEn:    tib['animal_month_en']  as String?,
        monthNameBo:      tib['month_name_bo']    as String?,
        yearNameBo:       tib['year_name_bo']     as String?,
        animalMonthBo:    tib['animal_month_bo']  as String?,
        animalYear:       tib['animal_month_en']  as String?,
        elementYear:      null,
      ),

      title:                    auspMap?['name_en'] as String?,
      titleBo:                  auspMap?['name_bo'] as String?,
      imageKey:                 json['image_key'] as String?,
      significanceEn:           sig?['day_significance_en']       as String?,
      significanceBo:           sig?['day_significance_bo']       as String?,
      elementCombination:       sig?['element_combo_en']          as String?,
      elementCombinationBo:     sig?['element_combo_bo']          as String?,
      elementCombinationDescBo: sig?['meaning_of_coincidence_bo'] as String?,
      elementCombinationDescEn: sig?['meaning_of_coincidence_en'] as String?,

      astrology: astrologyItems
          .map((e) => AstrologyStatusEntity(
                key:     e.key,
                labelEn: e.labelEn,
                labelBo: e.labelBo,
                status:  e.status,
                iconKey: e.iconKey,
              ))
          .toList(),

      directions:   const [],
      // No event IDs in inline events — navigation is handled by name lookup
      eventIds:     const [],
      astrologyItems:      astrologyItems,
      inlineEvents:        inlineEvents,
      tibetanDayDoubled:   tibetanDayDoubled,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static AstrologyStatusType _parseStatus(String s) {
    if (s == 'auspicious' || s == 'extremely_auspicious' || s == 'auspicious_minor') {
      return AstrologyStatusType.auspicious;
    }
    if (s == 'avoid' || s.startsWith('avoid_') || s.startsWith('avoid ')) {
      return AstrologyStatusType.inauspicious;
    }
    if (s == 'caution') return AstrologyStatusType.caution;
    return AstrologyStatusType.neutral;
  }
}

// ── AstrologyStatusModelItem ───────────────────────────────────────────────────

class AstrologyStatusModelItem {
  final String key;
  final String labelEn;
  final String labelBo;
  final AstrologyStatusType status;
  final String? subLabelEn;
  final String? subLabelBo;
  final String? iconKey;

  const AstrologyStatusModelItem({
    required this.key,
    required this.labelEn,
    required this.labelBo,
    required this.status,
    this.subLabelEn,
    this.subLabelBo,
    this.iconKey,
  });

  factory AstrologyStatusModelItem.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'neutral';
    final status = switch (statusStr) {
      'auspicious' || 'extremely_auspicious' || 'auspicious_minor'
          => AstrologyStatusType.auspicious,
      'avoid' => AstrologyStatusType.inauspicious,
      'caution' => AstrologyStatusType.caution,
      _ => AstrologyStatusType.neutral,
    };
    return AstrologyStatusModelItem(
      key:        json['key'] as String? ?? '',
      labelEn:    json['labelEn'] as String? ?? '',
      labelBo:    json['labelBo'] as String? ?? '',
      status:     status,
      subLabelEn: json['subLabelEn'] as String?,
      subLabelBo: json['subLabelBo'] as String?,
      iconKey:    json['iconKey'] as String?,
    );
  }
}
