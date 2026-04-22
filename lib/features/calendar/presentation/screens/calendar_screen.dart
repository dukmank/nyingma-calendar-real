import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/calendar_grid.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _monthNames = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// imageKey = English image,  imageKeyBo = Tibetan image (falls back to imageKey if same)
const _astroItems = [
  {'key': 'naga_days',            'label': 'NAGA\nDAYS',             'labelBo': 'ཀླུ་\nཐེབས།',           'icon': 0xe1b4, 'color': 0xFF2E7D32, 'imageKey': 'astrology_naga_days_major',        'imageKeyBo': 'astrology_naga_days_major'},
  {'key': 'flag_days',            'label': 'FLAG\nDAYS',             'labelBo': 'རྒྱལ་\nམཚན།',          'icon': 0xe3a9, 'color': 0xFF795548, 'imageKey': 'astrology_flag_days',              'imageKeyBo': 'astrology_flag_days'},
  {'key': 'fire_rituals',         'label': 'FIRE\nRITUALS',          'labelBo': 'མེ་\nམཆོད།',            'icon': 0xe248, 'color': 0xFFE64A19, 'imageKey': 'astrology_fire_rituals',           'imageKeyBo': 'astrology_fire_rituals'},
  {'key': 'empty_vase',           'label': 'EMPTY\nVASE',            'labelBo': 'བུམ་\nསྟོང་།',          'icon': 0xe3fe, 'color': 0xFF0288D1, 'imageKey': 'astrology_empty_vase',             'imageKeyBo': 'astrology_empty_vase'},
  {'key': 'torma_offerings',      'label': 'TORMA\nOFFERINGS',       'labelBo': 'གཏོར་\nམ།',             'icon': 0xe627, 'color': 0xFFC49A28, 'imageKey': 'astrology_torma_offerings',        'imageKeyBo': 'astrology_torma_offerings'},
  {'key': 'auspicious_times',     'label': 'AUSPICIOUS\nTIMES',      'labelBo': 'བཀྲ་ཤིས་\nཆུ་ཚོད།',    'icon': 0xe02b, 'color': 0xFF8B1A1A, 'imageKey': 'astrology_auspicious_time',        'imageKeyBo': 'astrology_auspicious_time'},
  {'key': 'hair_cutting',         'label': 'HAIR\nCUTTING',          'labelBo': 'སྐྲ་\nགཅོད།',           'icon': 0xe148, 'color': 0xFF455A64, 'imageKey': 'astrology_hair_cutting',           'imageKeyBo': 'astrology_hair_cutting'},
  {'key': 'horse_death',          'label': 'HORSE\nDEATH',           'labelBo': 'རྟ་\nའདས།',             'icon': 0xe002, 'color': 0xFFAD1457, 'imageKey': 'astrology_horse_death',            'imageKeyBo': 'astrology_horse_death'},
  {'key': 'fatal_weekdays',       'label': 'FATAL\nWEEKDAYS',        'labelBo': 'གཤེད་\nཉིན།',           'icon': 0xe3f0, 'color': 0xFF6D4C41, 'imageKey': 'astrology_fatal_weekdays',         'imageKeyBo': 'astrology_fatal_weekdays'},
  {'key': 'parkha',               'label': 'PARKHA\nTRIGRAMS',       'labelBo': 'པར་\nཁ།',              'icon': 0xe3ee, 'color': 0xFF7B1FA2, 'imageKey': 'astrology_parkha_eng',             'imageKeyBo': 'astrology_parkha_bo'},
  {'key': 'life_force_male',      'label': 'LIFE FORCE\nMALE',       'labelBo': 'སྲོག་ཤིང་\nཕོ།',       'icon': 0xe3e8, 'color': 0xFF1565C0, 'imageKey': 'astrology_life_force_male_eng',    'imageKeyBo': 'astrology_life_force_male_bo'},
  {'key': 'life_force_female',    'label': 'LIFE FORCE\nFEMALE',     'labelBo': 'སྲོག་ཤིང་\nམོ།',       'icon': 0xe3e7, 'color': 0xFFC2185B, 'imageKey': 'astrology_life_force_female_eng',  'imageKeyBo': 'astrology_life_force_female_bo'},
  {'key': 'gu_mig',               'label': 'GU-MIG\n9 EYES',         'labelBo': 'གུ་\nམིག',              'icon': 0xe417, 'color': 0xFF00838F, 'imageKey': 'astrology_gu_mig',                'imageKeyBo': 'astrology_gu_mig'},
  {'key': 'eye_twitching',        'label': 'EYE\nTWITCHING',         'labelBo': 'མིག་\nའདར།',           'icon': 0xe417, 'color': 0xFF558B2F, 'imageKey': 'astrology_eye_twitching_eng',      'imageKeyBo': 'astrology_eye_twitching_bo'},
  {'key': 'restriction_activities','label': 'RESTRICTED\nACTIVITIES','labelBo': 'ལྡོག་\nཆ།',            'icon': 0xe14f, 'color': 0xFFBF360C, 'imageKey': 'astrology_daily_restrictions_guest','imageKeyBo': 'astrology_daily_restrictions_guest'},
];

// ── Screen ────────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarControllerProvider);
    final ctrl  = ref.read(calendarControllerProvider.notifier);
    final bo    = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sticky AppBar ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 52,
            titleSpacing: 16,
            title: Row(
              children: [
                // Logo
                Container(
                  width: 36,
                  height: 36,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AppNetworkImage(imageKey: 'logo', fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NYINGMAPA',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      bo ? 'ལོ་ཐོ།' : 'Calendar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Language toggle
              GestureDetector(
                onTap: () => ref.read(languageProvider.notifier).state = !bo,
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    bo ? 'EN' : 'བོད',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 22),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                padding: const EdgeInsets.only(right: 16),
                onPressed: () {},
              ),
            ],
          ),

          // ── Hero Banner ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroBanner(
              state: state,
              bo: bo,
              onGoToToday: ctrl.goToToday,
              onTapDay: (key) => context.push(RouteNames.dayDetailOf(key)),
            ),
          ),

          // ── Calendar grid + month header ──────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month navigation header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 12, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Big month + year heading
                              Text(
                                state.monthData != null
                                    ? (bo
                                        ? '${tibMonthFull(state.month)} ${toTibNum(state.year)}'
                                        : '${_monthNames[state.month]} ${state.year}')
                                    : '',
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Tibetan month name + year label sub-line
                              if (state.monthData != null)
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: bo
                                            ? state.monthData!.tibetanMonthBo
                                            : '${state.monthData!.tibetanMonthEn} (Month ${state.month})',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.gold,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // Fallback: show Tibetan year number
                                      TextSpan(
                                        text: () {
                                          final yn = bo
                                              ? (state.monthData?.yearNameBo ?? '')
                                              : (state.monthData?.yearNameEn ?? '');
                                          if (yn.isEmpty) return '  •  YEAR ${state.year}';
                                          return bo
                                              ? '  •  $yn'
                                              : '  •  YEAR OF THE ${yn.toUpperCase()}';
                                        }(),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Navigation arrows
                        Column(
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _NavBtn(icon: Icons.chevron_left,  onTap: ctrl.goToPreviousMonth),
                                const SizedBox(width: 6),
                                _NavBtn(icon: Icons.chevron_right, onTap: ctrl.goToNextMonth),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.isLoading)
                    const SizedBox(height: 220, child: AppLoading())
                  else if (state.monthData != null)
                    CalendarGrid(
                      monthData: state.monthData!,
                      selectedDateKey: state.selectedDateKey,
                      bo: bo,
                      onDateSelected: (key) => ctrl.selectDate(key),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Change Day ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ChangeDaySection(
              state: state,
              bo: bo,
              onDateSelected: ctrl.selectDate,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Tibetan Astrology ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _AstrologyGrid(
              onItemTap: (key) => context.push(RouteNames.astrologyDetailOf(key)),
              bo: bo,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends ConsumerStatefulWidget {
  final CalendarState state;
  final bool bo;
  final VoidCallback onGoToToday;
  final ValueChanged<String> onTapDay;

  const _HeroBanner({
    required this.state,
    required this.bo,
    required this.onGoToToday,
    required this.onTapDay,
  });

  @override
  ConsumerState<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<_HeroBanner> {
  Map<String, dynamic>? _dayData;
  String? _loadedKey;

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  @override
  void didUpdateWidget(_HeroBanner old) {
    super.didUpdateWidget(old);
    if (old.state.selectedDateKey != widget.state.selectedDateKey ||
        old.state.monthData != widget.state.monthData) {
      _loadDayData();
    }
  }

  Future<void> _loadDayData() async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final target = widget.state.selectedDateKey ?? todayKey;
    if (target == _loadedKey) return;

    try {
      final parts = target.split('-');
      final year  = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final json  = await ref.read(remoteDataCacheProvider)
          .getJson(AppConstants.calendarPath(year, month));
      final days  = (json['days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      Map<String, dynamic>? found;
      for (final d in days) {
        if (d['date_key'] == target) { found = d; break; }
      }
      if (mounted) setState(() { _dayData = found; _loadedKey = target; });
    } catch (_) {
      if (mounted) setState(() => _dayData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now      = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final target   = widget.state.selectedDateKey ?? todayKey;
    final parts    = target.split('-');
    final gregDay   = int.tryParse(parts.length == 3 ? parts[2] : '') ?? now.day;
    final gregMonth = int.tryParse(parts.length == 3 ? parts[1] : '') ?? now.month;
    final gregYear  = int.tryParse(parts.length == 3 ? parts[0] : '') ?? now.year;

    // Auspicious day name
    final auspNameEn = _dayData?['auspicious_day_name_en'] as String?;
    final auspNameBo = _dayData?['auspicious_day_name_bo'] as String?;
    final auspName   = widget.bo ? (auspNameBo ?? auspNameEn) : auspNameEn;

    // Lunar info for amber panel
    final tibDayNum   = _dayData?['tibetan_day_en']   as String? ?? '--';
    final tibMonthNum = _dayData?['tibetan_month_en'] as String? ?? '--';
    final tibYearNum  = _dayData?['tibetan_year_en']  as String? ?? gregYear.toString();
    // In bo mode use Tibetan-script numerals; EN mode uses Arabic
    final tibDayDisp   = widget.bo ? (_dayData?['tibetan_day_bo']   as String? ?? tibDayNum)   : tibDayNum;
    final tibMonDisp   = widget.bo ? (_dayData?['tibetan_month_bo'] as String? ?? tibMonthNum) : tibMonthNum;
    final tibYearDisp  = widget.bo ? (_dayData?['tibetan_year_bo']  as String? ?? tibYearNum)  : tibYearNum;
    // Lunar date display — Tibetan uses "·" separator, EN uses "-"
    final lunarDate = widget.bo
        ? '$tibDayDisp · $tibMonDisp · $tibYearDisp'
        : '${tibDayNum.padLeft(2, '0')}-${tibMonthNum.padLeft(2, '0')}-$tibYearNum';

    // Three columns in amber panel — all from Excel data via JSON; use bo variants when available
    final elementDay  = widget.bo
        ? (_dayData?['element_combo_bo']     as String? ?? _dayData?['element_combo_en']     as String? ?? '—')
        : (_dayData?['element_combo_en']     as String? ?? '—');
    final monthAnimal = widget.bo
        ? (_dayData?['animal_month_bo']      as String? ?? _dayData?['animal_month_en']      as String? ?? '—')
        : (_dayData?['animal_month_en']      as String? ?? '—');
    final yearNameFull = widget.bo
        ? (_dayData?['tibetan_year_name_bo'] as String? ?? _dayData?['tibetan_year_name_en'] as String? ?? '—')
        : (_dayData?['tibetan_year_name_en'] as String? ?? _dayData?['tibetan_year_en'] as String? ?? '—');
    // EN: split "Fire Horse" → two lines.  BO: single Tibetan string, no split needed
    final yearParts = widget.bo ? [yearNameFull] : yearNameFull.split(' ');
    final yearLine1 = yearParts.isNotEmpty ? yearParts[0] : yearNameFull;
    final yearLine2 = yearParts.length > 1 ? yearParts[1] : '';

    final weatherState = ref.watch(weatherProvider);
    final useCelsius   = ref.watch(tempUnitCelsiusProvider);
    final isToday = target == todayKey;
    final imageKey = (_dayData?['image_key']?.toString()) ??
        (((gregDay - 1) % 8) + 1).toString();

    return GestureDetector(
      onTap: () => widget.onTapDay(target),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ── Background image ──────────────────────────────────
            Positioned.fill(
              child: AppNetworkImage(imageKey: imageKey, fit: BoxFit.cover),
            ),
            // ── Gradient overlay (light top → dark bottom) ────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top section: date + weather ───────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: huge day number + month text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bo ? toTibNum(gregDay) : gregDay.toString(),
                              style: const TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 80,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 0.85,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.bo
                                  ? tibMonthFull(gregMonth)
                                  : _monthNames[gregMonth].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: widget.bo ? 1 : 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: weather block (tappable when no location)
                      _WeatherBlock(
                        state:      weatherState,
                        useCelsius: useCelsius,
                        bo:         widget.bo,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Middle row: badge + location ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Auspicious badge (only when there is one)
                      if (auspName != null && auspName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            widget.bo ? auspName : auspName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        )
                      else
                        // "Go back to today" when another day is selected
                        if (!isToday)
                          GestureDetector(
                            onTap: widget.onGoToToday,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                widget.bo ? '← དེ་རིང་ལ་ལོག།' : '← GO BACK TO TODAY',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Amber panel: lunar date + 3 columns ──────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.88),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: LUNAR DATE + formatted value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.bo ? 'ཚེས་གྲངས།' : 'LUNAR DATE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: widget.bo ? 0 : 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lunarDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Vertical divider
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      // Three columns: DAY / MONTH / YEAR
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _LunarColumn(label: widget.bo ? 'ཉིན།'  : 'DAY',   line1: elementDay),
                            _LunarColumn(label: widget.bo ? 'ཟླ།'   : 'MONTH', line1: monthAnimal),
                            _LunarColumn(label: widget.bo ? 'ལོ།'   : 'YEAR',  line1: yearLine1, line2: yearLine2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weather Block (top-right of hero) ─────────────────────────────────────────

class _WeatherBlock extends ConsumerWidget {
  final WeatherState state;
  final bool         useCelsius;
  final bool         bo;

  const _WeatherBlock({required this.state, required this.useCelsius, this.bo = false});

  /// Shows the "Enable location" dialog, then requests permission.
  Future<void> _requestLocation(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(weatherProvider.notifier);
    final permanently = await notifier.isPermanentlyDenied();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          bo ? 'གནས་ས་ཆ་འཛིན།' : 'Enable Location',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          bo
              ? (permanently
                  ? 'གནས་ས་ཆ་འཛིན་མི་ཆོག་པར་བཀག། གནས་ས་ཆ་འཛིན་ལག་བྱེད་ལ་ཐུགས་ཞིབ་གནང་།'
                  : 'གནམ་གཤིས་མཐོང་བར་གནས་ས་ཆ་འཛིན་ལག་བྱེད་ཕྱེ་རོགས།')
              : (permanently
                  ? 'Location access was denied. Please enable it in your device Settings to see weather.'
                  : 'Enable location to view weather for your current location.'),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              bo ? 'སྤང་།' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (permanently) {
                await Geolocator.openAppSettings();
              } else {
                await notifier.requestPermission();
              }
            },
            child: Text(permanently
                ? (bo ? 'སྒྲིག་བཀོད།' : 'Open Settings')
                : (bo ? 'ཆོག' : 'Allow')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Loading state ─────────────────────────────────────────────────────
    if (state.isLoading) {
      return const SizedBox(
        width: 90,
        height: 70,
        child: Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white54),
          ),
        ),
      );
    }

    // ── No location granted: show dashes, tap to request ─────────────────
    if (!state.hasLocation || state.data == null) {
      return GestureDetector(
        onTap: () => _requestLocation(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_off_outlined,
                    color: Colors.white54, size: 18),
                SizedBox(width: 5),
                Text(
                  '—',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              '— —',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bo ? 'གནས་ས་གནང།' : 'TAP TO ENABLE',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    // ── Weather data available ────────────────────────────────────────────
    final w = state.data!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon + temperature
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(w.icon, color: Colors.white, size: 22),
            const SizedBox(width: 5),
            Text(
              w.tempDisplay(useCelsius),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Condition label
        Text(
          w.condition,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        // H / L
        if (w.highDisplay(useCelsius) != null &&
            w.lowDisplay(useCelsius) != null) ...[
          const SizedBox(height: 2),
          Text(
            '${w.highDisplay(useCelsius)}  ${w.lowDisplay(useCelsius)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        // City name — bottom of block
        if (w.city.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on,
                  color: Colors.white60, size: 10),
              const SizedBox(width: 2),
              Text(
                w.city,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Lunar Column (inside amber panel) ────────────────────────────────────────

class _LunarColumn extends StatelessWidget {
  final String label;
  final String line1;
  final String line2;
  const _LunarColumn({required this.label, required this.line1, this.line2 = ''});

  static const _valueStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(line1, style: _valueStyle, textAlign: TextAlign.center),
          if (line2.isNotEmpty)
            Text(line2, style: _valueStyle, textAlign: TextAlign.center),
        ],
      );
}

// ── Nav Button ────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      );
}

// ── Change Day Section ────────────────────────────────────────────────────────

class _ChangeDaySection extends ConsumerStatefulWidget {
  final CalendarState state;
  final bool bo;
  final ValueChanged<String> onDateSelected;

  const _ChangeDaySection({
    required this.state,
    required this.bo,
    required this.onDateSelected,
  });

  @override
  ConsumerState<_ChangeDaySection> createState() => _ChangeDaySectionState();
}

class _ChangeDaySectionState extends ConsumerState<_ChangeDaySection> {
  // All JSON days: dateKey → raw data
  final Map<String, Map<String, dynamic>> _lookup   = {};
  // Tibetan "year-month-day" → dateKey
  final Map<String, String>              _tibLookup = {};

  // Gregorian wheel values
  final _gDays   = List.generate(31, (i) => i + 1);
  final _gMonths = List.generate(12, (i) => i + 1);
  final _gYears  = [2026, 2027];

  // Tibetan wheel values
  final _tDays   = List.generate(30, (i) => i + 1);
  final _tMonths = List.generate(12, (i) => i + 1);
  final _tYears  = [2153, 2154];

  late FixedExtentScrollController _gDayC, _gMonC, _gYeC;
  late FixedExtentScrollController _tDayC, _tMonC, _tYeC;

  Map<String, dynamic>? _data;

  // Sync control — true while we're programmatically animating the OTHER drum
  bool _programmaticSync = false;
  Timer? _gregDebounce;
  Timer? _tibDebounce;

  // ── init ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final sel = _resolveKey();
    final p   = sel.split('-');
    final gD  = int.tryParse(p[2]) ?? 1;
    final gM  = int.tryParse(p[1]) ?? 1;
    final gY  = int.tryParse(p[0]) ?? 2026;

    _gDayC = FixedExtentScrollController(initialItem: (_gDays.indexOf(gD)).clamp(0, 30));
    _gMonC = FixedExtentScrollController(initialItem: (_gMonths.indexOf(gM)).clamp(0, 11));
    _gYeC  = FixedExtentScrollController(initialItem: (_gYears.indexOf(gY)).clamp(0, _gYears.length - 1));
    _tDayC = FixedExtentScrollController(initialItem: 0);
    _tMonC = FixedExtentScrollController(initialItem: 0);
    _tYeC  = FixedExtentScrollController(initialItem: 0);

    _loadData();
  }

  @override
  void dispose() {
    _gregDebounce?.cancel();
    _tibDebounce?.cancel();
    for (final c in [_gDayC, _gMonC, _gYeC, _tDayC, _tMonC, _tYeC]) c.dispose();
    super.dispose();
  }

  String _resolveKey() {
    if (widget.state.selectedDateKey != null) return widget.state.selectedDateKey!;
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  // ── data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final cache = ref.read(remoteDataCacheProvider);
    final months = [
      (2026,2),(2026,3),(2026,4),(2026,5),(2026,6),(2026,7),
      (2026,8),(2026,9),(2026,10),(2026,11),(2026,12),(2027,1),(2027,2),
    ];
    for (final (y, m) in months) {
      try {
        final json = await cache.getJson(AppConstants.calendarPath(y, m));
        for (final d in (json['days'] as List).cast<Map<String,dynamic>>()) {
          final k = d['date_key'] as String? ?? '';
          if (k.isEmpty) continue;
          _lookup[k] = d;
          final td = d['tibetan_day_en'], tm = d['tibetan_month_en'], ty = d['tibetan_year_en'];
          if (td != null && tm != null && ty != null) {
            _tibLookup['$ty-$tm-$td'] = k;
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final sel = _resolveKey();
    setState(() => _data = _lookup[sel]);
    _doSyncTibFromGreg(sel);
  }

  // ── animate helper ────────────────────────────────────────────────────────────

  void _animateTo(FixedExtentScrollController c, int idx) {
    if (!c.hasClients) return;
    c.animateToItem(
      idx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // ── sync: Gregorian → Tibetan ─────────────────────────────────────────────────

  void _doSyncTibFromGreg(String dateKey) {
    final d = _lookup[dateKey];
    if (d == null) return;
    final tDay = int.tryParse(d['tibetan_day_en']?.toString()   ?? '') ?? 1;
    final tMon = int.tryParse(d['tibetan_month_en']?.toString() ?? '') ?? 1;
    final tYr  = int.tryParse(d['tibetan_year_en']?.toString()  ?? '') ?? 2153;
    _programmaticSync = true;
    _animateTo(_tDayC, _tDays.indexOf(tDay).clamp(0, _tDays.length - 1));
    _animateTo(_tMonC, _tMonths.indexOf(tMon).clamp(0, _tMonths.length - 1));
    _animateTo(_tYeC,  _tYears.indexOf(tYr).clamp(0, _tYears.length - 1));
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _programmaticSync = false;
    });
  }

  // ── sync: Tibetan → Gregorian ─────────────────────────────────────────────────

  void _doSyncGregFromTib(int tDay, int tMon, int tYr) {
    final key = _tibLookup['$tYr-$tMon-$tDay'];
    if (key == null) return;
    final p  = key.split('-');
    final gD = int.tryParse(p[2]) ?? 1;
    final gM = int.tryParse(p[1]) ?? 1;
    final gY = int.tryParse(p[0]) ?? 2026;
    _programmaticSync = true;
    _animateTo(_gDayC, _gDays.indexOf(gD).clamp(0, _gDays.length - 1));
    _animateTo(_gMonC, _gMonths.indexOf(gM).clamp(0, _gMonths.length - 1));
    _animateTo(_gYeC,  _gYears.indexOf(gY).clamp(0, _gYears.length - 1));
    if (mounted) {
      setState(() => _data = _lookup[key]);
      widget.onDateSelected(key);
    }
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _programmaticSync = false;
    });
  }

  // ── wheel callbacks ───────────────────────────────────────────────────────────

  // Called on every Gregorian wheel item change
  void _onGregItemChanged(int _) {
    if (_programmaticSync) return;
    if (!_gDayC.hasClients || !_gMonC.hasClients || !_gYeC.hasClients) return;

    // Update info bar immediately for responsiveness
    final gD  = _gDays[_gDayC.selectedItem.clamp(0, _gDays.length - 1)];
    final gM  = _gMonths[_gMonC.selectedItem.clamp(0, _gMonths.length - 1)];
    final gY  = _gYears[_gYeC.selectedItem.clamp(0, _gYears.length - 1)];
    final key = '$gY-${gM.toString().padLeft(2,'0')}-${gD.toString().padLeft(2,'0')}';
    if (mounted) setState(() => _data = _lookup[key]);

    // Debounce: sync Tibetan drum only after user settles
    _gregDebounce?.cancel();
    _gregDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || _programmaticSync) return;
      if (_lookup.containsKey(key)) {
        widget.onDateSelected(key);
        _doSyncTibFromGreg(key);
      }
    });
  }

  // Called on every Tibetan wheel item change
  void _onTibItemChanged(int _) {
    if (_programmaticSync) return;
    if (!_tDayC.hasClients || !_tMonC.hasClients || !_tYeC.hasClients) return;

    final tD  = _tDays[_tDayC.selectedItem.clamp(0, _tDays.length - 1)];
    final tM  = _tMonths[_tMonC.selectedItem.clamp(0, _tMonths.length - 1)];
    final tY  = _tYears[_tYeC.selectedItem.clamp(0, _tYears.length - 1)];

    // Update info bar immediately
    final key = _tibLookup['$tY-$tM-$tD'];
    if (key != null && mounted) setState(() => _data = _lookup[key]);

    // Debounce: sync Gregorian drum only after user settles
    _tibDebounce?.cancel();
    _tibDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || _programmaticSync) return;
      _doSyncGregFromTib(tD, tM, tY);
    });
  }

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bo = widget.bo;
    final d  = _data;

    // Bottom bar data — use bo variants when language=Tibetan
    final tibDayBo  = d?['tibetan_day_bo']      as String? ?? '—';
    final elemDay   = bo
        ? (d?['element_combo_bo']     as String? ?? d?['element_combo_en']     as String? ?? '—')
        : (d?['element_combo_en']     as String? ?? '—');
    final animalMon = bo
        ? (d?['animal_month_bo']      as String? ?? d?['animal_month_en']      as String? ?? '—')
        : (d?['animal_month_en']      as String? ?? '—');
    final yearName  = bo
        ? (d?['tibetan_year_name_bo'] as String? ?? d?['tibetan_year_name_en'] as String? ?? '—')
        : (d?['tibetan_year_name_en'] as String? ?? '—');
    // EN: split "Fire Horse" → two lines.  BO: keep as one Tibetan string
    final yearParts = bo ? [yearName] : yearName.split(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.edit_calendar_outlined, size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                bo ? 'ཉིན་བསྒྱུར།' : 'CHANGE DAY',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Gregorian drum ───────────────────────────────────────────
          _CalendarLabel(text: bo ? 'ལོ་ཐོ་ཕྱི་མའི།' : 'GREGORIAN CALENDAR', color: AppColors.primary),
          _DrumPicker(
            dayCtrl: _gDayC, monCtrl: _gMonC, yrCtrl: _gYeC,
            days: _gDays, months: _gMonths, years: _gYears,
            activeColor: AppColors.primary,
            bo: false,   // Gregorian always Arabic
            onItemChanged: _onGregItemChanged,
          ),

          const Divider(height: 1, thickness: 0.5, color: AppColors.divider, indent: 16, endIndent: 16),

          // ── Tibetan drum ────────────────────────────────────────────
          _CalendarLabel(text: bo ? 'ལོ་ཐོ་བོད་ཀྱི།' : 'TIBETAN CALENDAR', color: AppColors.gold),
          _DrumPicker(
            dayCtrl: _tDayC, monCtrl: _tMonC, yrCtrl: _tYeC,
            days: _tDays, months: _tMonths, years: _tYears,
            activeColor: AppColors.gold,
            bo: bo,      // Tibetan drum shows Tibetan numerals when bo=true
            onItemChanged: _onTibItemChanged,
          ),

          // ── Gold info bar ────────────────────────────────────────────
          Container(
            color: AppColors.gold,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _InfoCell(
                  label: bo ? 'ཉིན།' : 'DATE',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tibDayBo,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        elemDay,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                _InfoCell(
                  label: bo ? 'ཟླ།' : 'MONTH',
                  child: Text(
                    animalMon,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                _InfoCell(
                  label: bo ? 'ལོ།' : 'YEAR',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        yearParts.isNotEmpty ? yearParts[0] : yearName,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      if (yearParts.length > 1)
                        Text(
                          yearParts.sublist(1).join(' '),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Support widgets ───────────────────────────────────────────────────────────

class _CalendarLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _CalendarLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
      );
}

class _DrumPicker extends StatelessWidget {
  final FixedExtentScrollController dayCtrl, monCtrl, yrCtrl;
  final List<int> days, months, years;
  final Color activeColor;
  final bool bo;
  final ValueChanged<int> onItemChanged;

  const _DrumPicker({
    required this.dayCtrl, required this.monCtrl, required this.yrCtrl,
    required this.days, required this.months, required this.years,
    required this.activeColor,
    this.bo = false,
    required this.onItemChanged,
  });

  static const _h     = 44.0;
  static const _total = _h * 3;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centre highlight band
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: _h,
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            Row(children: [
              _Drum(ctrl: dayCtrl,  items: days,   active: activeColor, h: _total, bo: bo, onItemChanged: onItemChanged),
              _Drum(ctrl: monCtrl,  items: months, active: activeColor, h: _total, bo: bo, onItemChanged: onItemChanged),
              _Drum(ctrl: yrCtrl,   items: years,  active: activeColor, h: _total, bo: bo, onItemChanged: onItemChanged),
            ]),
          ],
        ),
      );
}

// StatefulWidget so _selected updates live during scroll for smooth highlight
class _Drum extends StatefulWidget {
  final FixedExtentScrollController ctrl;
  final List<int> items;
  final Color active;
  final double h;
  final bool bo;
  final ValueChanged<int> onItemChanged;

  const _Drum({
    required this.ctrl, required this.items, required this.active,
    required this.h, this.bo = false, required this.onItemChanged,
  });

  @override
  State<_Drum> createState() => _DrumState();
}

class _DrumState extends State<_Drum> {
  static const _itemH = 44.0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.ctrl.initialItem;
  }

  @override
  Widget build(BuildContext context) => Expanded(
        child: SizedBox(
          height: widget.h,
          child: ListWheelScrollView.useDelegate(
            controller: widget.ctrl,
            itemExtent: _itemH,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            diameterRatio: 2.8,
            squeeze: 1.1,
            onSelectedItemChanged: (i) {
              setState(() => _selected = i);
              widget.onItemChanged(i);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (ctx, i) {
                final sel    = i == _selected;
                final numStr = widget.bo
                    ? toTibNum(widget.items[i])
                    : widget.items[i].toString();
                return Center(
                  child: Text(
                    numStr,
                    style: TextStyle(
                      fontSize: sel ? 18 : 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel
                          ? widget.active
                          : AppColors.textMuted.withOpacity(0.45),
                      height: 1.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _InfoCell extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoCell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      );
}

// ── Tibetan Astrology Grid ────────────────────────────────────────────────────

class _AstrologyGrid extends StatelessWidget {
  final ValueChanged<String>? onItemTap;
  final bool bo;

  const _AstrologyGrid({this.onItemTap, required this.bo});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AppNetworkImage(imageKey: 'astrology_main', fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    bo ? 'བོད་རྟགས།' : 'TIBETAN ASTROLOGY',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: _astroItems.length,
                itemBuilder: (context, i) {
                  final item = _astroItems[i];
                  // Pick EN or Tibetan image based on current language
                  final imageKey = bo
                      ? (item['imageKeyBo'] as String)
                      : (item['imageKey'] as String);
                  return GestureDetector(
                    onTap: () => onItemTap?.call(item['key'] as String),
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background image — no color overlay, full image visible
                          AppNetworkImage(imageKey: imageKey, fit: BoxFit.cover),
                          // Subtle dark scrim only at bottom so label text is readable
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            height: 28,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xBB000000)],
                                ),
                              ),
                            ),
                          ),
                          // Label at bottom
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 5),
                              child: Text(
                                bo
                                    ? (item['labelBo'] as String)
                                    : (item['label'] as String),
                                style: const TextStyle(
                                  fontSize: 7.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  height: 1.3,
                                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}
