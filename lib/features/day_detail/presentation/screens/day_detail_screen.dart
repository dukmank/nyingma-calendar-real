import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_error.dart';
import '../controllers/day_detail_controller.dart';
import '../../data/models/day_detail_model.dart';
import '../../../../app/router/route_names.dart';
import '../widgets/day_header.dart';
import '../widgets/day_significance.dart';
import '../widgets/daily_wisdom.dart';
import '../widgets/element_section.dart';
import '../widgets/astrology_status_list.dart';
import '../../../profile/domain/entities/user_event_entity.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class DayDetailScreen extends ConsumerWidget {
  final String dateKey;

  const DayDetailScreen({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail  = ref.watch(dayDetailProvider(dateKey));
    final bo           = ref.watch(languageProvider);
    final profileAsync = ref.watch(profileProvider);

    // Is this day already saved as a personal event?
    final isSaved = profileAsync.whenOrNull(
          data: (s) => s.events.any((e) => e.dateKey == dateKey),
        ) ??
        false;

    Future<void> toggleSave() async {
      if (isSaved) {
        // Remove
        final profileState = ref.read(profileProvider).value;
        final existing = profileState?.events.where((e) => e.dateKey == dateKey).toList() ?? [];
        for (final e in existing) {
          await ref.read(profileProvider.notifier).deleteEvent(e.id);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(bo ? 'དུས་ཆེན་བསུབས།' : 'Removed from your events'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      } else {
        // Save — get detail from the provider to build a rich event
        final detail = asyncDetail.value;
        final title = detail?.title ?? dateKey;
        final lunarDayStr = detail?.tibetan.dayEn ?? detail?.tibetan.day ?? '';
        final lunarDay = int.tryParse(lunarDayStr) ?? 0;
        final lunarLabel = lunarDay > 0 ? 'Lunar Day $lunarDay' : '';
        final now = DateTime.now();
        final event = UserEventEntity(
          id: '',
          title: title,
          dateKey: dateKey,
          lunarDay: lunarDay,
          lunarLabel: lunarLabel,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(profileProvider.notifier).addEvent(event);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(bo ? 'ང་ཡི་དུས་ཆེན་ལ་ཉར།' : 'Saved to your events'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    }

    // Build month label from dateKey for the app bar: "APR 2026"
    final parts = dateKey.split('-');
    final _monthNames = const [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final monthIdx  = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final monthLabel = parts.length >= 2
        ? '${_monthNames.elementAtOrNull(monthIdx) ?? ''} ${parts[0]}'
        : dateKey;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── Sticky red nav bar ──────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ),
                  ),
                  // Month label (centered)
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  // Share
                  GestureDetector(
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.share_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  // Favorite
                  GestureDetector(
                    onTap: toggleSave,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 14, 0),
                      child: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved ? Colors.red.shade300 : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: asyncDetail.when(
        loading: () => const AppLoading(message: 'Loading...'),
        error: (e, _) => const AppError(message: 'Could not load day details'),
        data: (detail) {
          if (detail == null) {
            return _EmptyDayDetail(
                dateKey: dateKey, bo: bo, onSave: toggleSave, isSaved: isSaved);
          }
          return _DayDetailContent(detail: detail, bo: bo);
        },
      ),
    );
  }
}

class _DayDetailContent extends StatelessWidget {
  final DayDetailModel detail;
  final bool bo;

  const _DayDetailContent({required this.detail, required this.bo});

  @override
  Widget build(BuildContext context) {
    String s(String en, String tib) => bo ? tib : en;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayHeader(detail: detail, bo: bo),

          const SizedBox(height: 8),

          if (detail.significanceEn != null || detail.significanceBo != null)
            DaySignificanceCard(
              title: detail.title,
              titleBo: detail.titleBo,
              significanceEn: detail.significanceEn,
              significanceBo: detail.significanceBo,
              bo: bo,
            ),

          if (detail.wisdomEn != null)
            DailyWisdomCard(
              wisdom: detail.wisdomEn!,
              author: detail.wisdomAuthor,
              bo: bo,
            ),

          if (detail.elementCombination != null || detail.elementCombinationBo != null)
            ElementCombinationCard(
              combination: detail.elementCombination ?? '',
              combinationBo: detail.elementCombinationBo,
              description: detail.elementCombinationDescEn,
              descriptionBo: detail.elementCombinationDescBo,
              bo: bo,
            ),

          if (detail.astrologyItems.isNotEmpty)
            AstrologyStatusList(
              items: detail.astrologyItems,
              bo: bo,
              onItemTap: (key) {
                // Map day_detail card type keys → astrology route keys
                const _keyMap = <String, String>{
                  'naga_day'          : 'naga_days',
                  'flag_day'          : 'flag_days',
                  'fire_ritual'       : 'fire_rituals',
                  'hair_cutting'      : 'hair_cutting',
                  'horse_death'       : 'horse_death',
                  'torma_offering'    : 'torma_offerings',
                  'empty_vase'        : 'empty_vase',
                  'daily_restriction' : 'restriction_activities',
                  'auspicious_times'  : 'auspicious_times',
                  'life_force_male'   : 'life_force_male',
                  'life_force_female' : 'life_force_female',
                  'gu_mig'            : 'gu_mig',
                  'fatal_weekdays'    : 'fatal_weekdays',
                  'eye_twitching'     : 'eye_twitching',
                  'parkha'            : 'parkha',
                };
                final routeKey = _keyMap[key] ?? key;
                context.push(RouteNames.astrologyDetailOf(routeKey));
              },
            ),

          // Show inline events (name + category + tap to full detail)
          if (detail.inlineEvents.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(children: [
                      Container(
                        width: 3, height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s("TODAY'S EVENTS", 'དེ་རིང་གི་དུས་ཆེན།'),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.gold, letterSpacing: 1.5),
                      ),
                    ]),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ...detail.inlineEvents.asMap().entries.map((entry) {
                    final i   = entry.key;
                    final evt = entry.value;
                    // Inline events have no ID — use "YYYY-MM-DD-{i}" as fallback key.
                    // EventDetailScreen resolves this by finding the i-th event for the date.
                    final id  = '${detail.dateKey}-$i';
                    return Column(children: [
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider),
                      _InlineEventCard(
                        eventId:  id,
                        event:    evt,
                        bo:       bo,
                      ),
                    ]);
                  }),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync_outlined, size: 18),
                label: Text(s('SYNC TO CALENDAR', 'ལོ་ཐོར་མཐུན།')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: AppTextStyles.labelLarge
                      .copyWith(color: Colors.white, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined,
                    size: 18, color: AppColors.gold),
                label: Text(s('SET REMINDER', 'དྲན་སྐུལ།'),
                    style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.gold, letterSpacing: 1.5)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.gold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Shows an inline event with real title + category, tapping opens the detail.
class _InlineEventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> event;
  final bool bo;

  const _InlineEventCard({
    required this.eventId,
    required this.event,
    required this.bo,
  });

  @override
  Widget build(BuildContext context) {
    final title = bo
        ? (event['name_bo'] as String? ?? event['name_en'] as String? ?? '')
        : (event['name_en'] as String? ?? '');
    final category = bo
        ? (event['category_bo'] as String? ?? event['category_en'] as String?)
        : (event['category_en'] as String?);

    return InkWell(
      onTap: () => context.push(RouteNames.eventDetailOf(eventId)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardAuspicious,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.temple_buddhist_outlined,
                color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall),
                if (category != null) ...[
                  const SizedBox(height: 2),
                  Text(category,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.gold)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

class _EmptyDayDetail extends StatelessWidget {
  final String dateKey;
  final bool bo;
  final VoidCallback onSave;
  final bool isSaved;

  const _EmptyDayDetail({
    required this.dateKey,
    required this.bo,
    required this.onSave,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split('-');
    final day = parts.length == 3 ? parts[2] : dateKey;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardAuspicious,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(day,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            bo ? 'ཉིན་འདིར་གཞི་གྲངས་མེད།' : 'No data available for this day',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(dateKey, style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),
          // Still allow saving even with no data
          OutlinedButton.icon(
            onPressed: onSave,
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: isSaved ? AppColors.primary : AppColors.textSecondary,
            ),
            label: Text(
              isSaved
                  ? (bo ? 'བསུབ།' : 'Remove')
                  : (bo ? 'ཉར།' : 'Save to profile'),
              style: AppTextStyles.labelLarge.copyWith(
                color: isSaved ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: isSaved
                      ? AppColors.primary
                      : AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
