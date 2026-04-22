import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../controllers/auspicious_controller.dart';

// ── Alias: the rest of the file uses _AuspDay, backed by AuspiciousDay ──────

typedef _AuspDay = AuspiciousDay;

// ── Short month labels ────────────────────────────────────────────────────────

const _monthShort = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthFull = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AuspiciousScreen extends ConsumerStatefulWidget {
  const AuspiciousScreen({super.key});

  @override
  ConsumerState<AuspiciousScreen> createState() => _AuspiciousScreenState();
}

class _AuspiciousScreenState extends ConsumerState<AuspiciousScreen> {
  DateTime _selectedDate = DateTime.now();

  // First day of the currently displayed week (Monday)
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  /// Returns the Monday that starts the week containing [d].
  DateTime _mondayOf(DateTime d) {
    final offset = (d.weekday - 1) % 7; // Mon=0 … Sun=6
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: offset));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  int _daysUntilFrom(_AuspDay d, DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    return d.date.difference(base).inDays;
  }

  /// Returns one entry per auspicious-day type, each being the FIRST occurrence
  /// on or after [from]. Sorted by date.
  List<_AuspDay> _nextPerType(List<_AuspDay> all, DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    final Map<String, _AuspDay> byType = {};
    for (final day in all) {
      if (day.date.isBefore(base)) continue;
      final key = day.nameEn.toLowerCase().trim();
      if (!byType.containsKey(key)) {
        byType[key] = day; // list is sorted, so first match is earliest
      }
    }
    final result = byType.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  bool _isAuspicious(DateTime dt, List<_AuspDay> upcoming) {
    final key =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    return upcoming.any((u) => u.dateKey == key);
  }

  SliverAppBar _buildAppBar(bool bo, String Function(String, String) s) =>
      SliverAppBar(
        pinned: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          s('Auspicious Days', 'བཀྲ་ཤིས་ཀྱི་ཉིན།'),
          style: AppTextStyles.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textSecondary, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => context.push(RouteNames.search),
          ),
          const SizedBox(width: 4),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final bo   = ref.watch(languageProvider);
    String s(String en, String tib) => bo ? tib : en;
    final auspAsync = ref.watch(auspiciousProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: auspAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            _buildAppBar(bo, s),
            const SliverFillRemaining(child: AppLoading()),
          ],
        ),
        error: (e, _) => CustomScrollView(
          slivers: [
            _buildAppBar(bo, s),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      s('Could not load auspicious days.\nPlease check your connection.',
                        'བཀྲ་ཤིས་ཀྱི་ཉིན་མ་མི་ཐོབ།\nར་སྤྲོད་བལྟས་རོགས།'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(auspiciousProvider),
                      child: Text(s('Retry', 'ཡང་བསྐྱར།')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (upcoming) {
          // Group by type from the selected date — drives both the card and the list
          final nearest       = _nextPerType(upcoming, _selectedDate);
          final _AuspDay? next = nearest.isNotEmpty ? nearest.first : null;

          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────────────────────
              _buildAppBar(bo, s),

              // ── Next milestone card ──────────────────────────────────────
              if (next != null)
                SliverToBoxAdapter(
                  child: _MilestoneCard(
                    day:       next,
                    daysUntil: _daysUntilFrom(next, DateTime.now()),
                    bo:        bo,
                    onViewDay: () =>
                        context.push(RouteNames.dayDetailOf(next.dateKey)),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Week date strip ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _WeekStrip(
                  weekDays:        _weekDays,
                  selectedDate:    _selectedDate,
                  auspiciousCheck: (dt) => _isAuspicious(dt, upcoming),
                  bo:              bo,
                  onSelect: (d) => setState(() => _selectedDate = d),
                  onPrevWeek: () => setState(
                      () => _weekStart =
                          _weekStart.subtract(const Duration(days: 7))),
                  onNextWeek: () => setState(
                      () => _weekStart =
                          _weekStart.add(const Duration(days: 7))),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Section header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    s('NEXT OCCURRENCE PER TYPE', 'རིགས་རེར་ཉིན་མཐར་མར་མཐོང་བ།'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),

              // ── All 6 auspicious day types, each with next upcoming date ──
              if (nearest.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _SignificantDateRow(
                      day:       nearest[i],
                      daysUntil: _daysUntilFrom(nearest[i], DateTime.now()),
                      bo:        bo,
                      onTap:     () =>
                          context.push(RouteNames.dayDetailOf(nearest[i].dateKey)),
                    ),
                    childCount: nearest.length,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        s('No upcoming auspicious days found',
                            'བཀྲ་ཤིས་ཀྱི་ཉིན་མ་མེད།'),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

// ── Next-milestone card ───────────────────────────────────────────────────────

class _MilestoneCard extends StatelessWidget {
  final _AuspDay     day;
  final int          daysUntil;
  final bool         bo;
  final VoidCallback onViewDay;

  const _MilestoneCard({
    required this.day,
    required this.daysUntil,
    required this.bo,
    required this.onViewDay,
  });

  @override
  Widget build(BuildContext context) {
    String s(String en, String tib) => bo ? tib : en;

    final countdownText = daysUntil == 0
        ? s('Today!', 'དེ་རིང་!')
        : daysUntil == 1
            ? s('In 1 Day', 'ཉིན་གཅིག་ནང་')
            : s('In $daysUntil Days', 'ཉིན་$daysUntil ནང་');

    final title = bo ? day.nameBo : day.nameEn;
    final desc  = (bo ? day.descBo : day.descEn);

    final lunarLabel = day.tibetanDayEn.isNotEmpty && day.tibetanMonthEn.isNotEmpty
        ? s(
            'Day ${day.tibetanDayEn} · Lunar Month ${day.tibetanMonthEn}',
            'ཉིན་${day.tibetanDayEn} · ཟླ་${day.tibetanMonthEn}',
          )
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: NEXT MILESTONE chip + countdown ────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s('NEXT MILESTONE', 'དུས་ཚོད་ཕྱི་མ།'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                countdownText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Title ────────────────────────────────────────────────────
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          if (lunarLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              lunarLabel,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ── Action buttons ───────────────────────────────────────────
          Row(
            children: [
              // View Day Details
              Expanded(
                child: GestureDetector(
                  onTap: onViewDay,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s('View Day Details', 'ཉིན་ཤེས་རྟོགས།'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Set Reminder
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s('Set Reminder', 'དྲན་བརྡ།'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Week strip ────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<DateTime>         weekDays;
  final DateTime               selectedDate;
  final bool Function(DateTime) auspiciousCheck;
  final bool                   bo;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback           onPrevWeek;
  final VoidCallback           onNextWeek;

  const _WeekStrip({
    required this.weekDays,
    required this.selectedDate,
    required this.auspiciousCheck,
    this.bo = false,
    required this.onSelect,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // ← prev week
          GestureDetector(
            onTap: onPrevWeek,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 4),

          // 7 day cells
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((d) {
                final isSel = d.year == selectedDate.year &&
                    d.month == selectedDate.month &&
                    d.day == selectedDate.day;
                final isToday = d == today;
                final isAusp  = auspiciousCheck(d);

                return GestureDetector(
                  onTap: () => onSelect(d),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Month abbrev
                      Text(
                        _monthShort[d.month],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSel
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Day number circle
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primary.withOpacity(0.08)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.primary.withOpacity(0.4)
                                    : Colors.transparent,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          d.day.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Auspicious dot
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: isAusp
                              ? (isSel ? Colors.white : AppColors.primary)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 4),
          // → next week
          GestureDetector(
            onTap: onNextWeek,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Significant date row ──────────────────────────────────────────────────────

class _SignificantDateRow extends StatelessWidget {
  final _AuspDay     day;
  final int          daysUntil;
  final bool         bo;
  final VoidCallback onTap;

  const _SignificantDateRow({
    required this.day,
    required this.daysUntil,
    required this.bo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String s(String en, String tib) => bo ? tib : en;

    final title     = bo ? day.nameBo : day.nameEn;
    final solarDate =
        '${_monthFull[day.date.month]} ${day.date.day}, ${day.date.year}';
    final lunarDate = day.tibetanMonthEn.isNotEmpty && day.tibetanDayEn.isNotEmpty
        ? s(
            'Lunar Month ${day.tibetanMonthEn} · Day ${day.tibetanDayEn}',
            'ཟླ་${day.tibetanMonthEn} · ཉིན་${day.tibetanDayEn}',
          )
        : '';

    final badge = daysUntil == 0
        ? s('Today', 'དེ་རིང་')
        : daysUntil == 1
            ? s('Tomorrow', 'སང་ཉིན་')
            : s('${daysUntil}d', '${daysUntil}ཉིན་');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: day.imageKey != null
                  ? AppNetworkImage(
                      imageKey: day.imageKey!,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.cardAuspicious,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.gold, size: 26),
                    ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    title,
                    style: AppTextStyles.titleSmall
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        s('SOLAR CALENDAR', 'ཉི་ལོ།'),
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        solarDate,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (lunarDate.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          s('LUNAR CALENDAR', 'ཟླ་ལོ།'),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lunarDate,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            // Days-until badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: daysUntil == 0
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: daysUntil == 0
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
