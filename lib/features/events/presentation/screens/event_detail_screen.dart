import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../profile/domain/entities/user_event_entity.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/event_entity.dart';
import '../controllers/events_controller.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: eventAsync.when(
        loading: () => const AppLoading(),
        error: (_, __) => _NotFound(onBack: () => context.pop(), bo: bo),
        data: (event) => event == null
            ? _NotFound(onBack: () => context.pop(), bo: bo)
            : _EventDetailBody(event: event, bo: bo, onBack: () => context.pop()),
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _EventDetailBody extends ConsumerWidget {
  final EventEntity event;
  final bool bo;
  final VoidCallback onBack;

  const _EventDetailBody({required this.event, required this.bo, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String s(String en, String tib) => bo ? tib : en;
    final title = bo && event.titleBo.isNotEmpty ? event.titleBo : event.titleEn;
    final profileAsync = ref.watch(profileProvider);

    final isSaved = profileAsync.whenOrNull(
          data: (st) => st.events.any((e) => e.content == 'calendar:${event.id}'),
        ) ?? false;

    void toggleSave() {
      profileAsync.whenData((pState) {
        if (isSaved) {
          final matches = pState.events.where((e) => e.content == 'calendar:${event.id}');
          if (matches.isNotEmpty) {
            ref.read(profileProvider.notifier).deleteEvent(matches.first.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s('Removed from saved', 'བསུབས་སོ།')),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        } else {
          final now = DateTime.now();
          final entity = UserEventEntity(
            id: '',
            title: title,
            content: 'calendar:${event.id}',
            dateKey: event.dateKey,
            imageKey: event.imageKey,
            createdAt: now,
            updatedAt: now,
          );
          ref.read(profileProvider.notifier).addEvent(entity);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s('Saved to your events', 'ང་ཡི་དུས་ཆེན་ལ་ཉར།')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.statusAuspicious,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      });
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image
          Stack(
            children: [
              event.imageKey != null && event.imageKey!.isNotEmpty
                  ? AppNetworkImage(
                      imageKey: event.imageKey!,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover)
                  : Container(
                      height: 240,
                      color: AppColors.cardAuspicious,
                      child: const Center(
                        child: Icon(Icons.temple_buddhist_outlined,
                            size: 80, color: AppColors.gold),
                      ),
                    ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleBtn(icon: Icons.chevron_left, onTap: onBack),
                      Row(children: [
                        _CircleBtn(icon: Icons.share_outlined, onTap: () {}),
                        const SizedBox(width: 8),
                        _CircleBtn(
                          icon: isSaved ? Icons.favorite : Icons.favorite_border,
                          iconColor: isSaved ? AppColors.primary : AppColors.textPrimary,
                          onTap: toggleSave,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),

                _DateRow(
                  icon: Icons.wb_sunny_outlined,
                  label: s('Date', 'ཚེས།'),
                  value: _formatDateKey(event.dateKey, bo),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 20),

                if (event.descriptionEn != null && event.descriptionEn!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(s('DETAIL', 'ཞིབ་འཇུག'),
                          style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bo && (event.descriptionBo?.isNotEmpty ?? false)
                        ? event.descriptionBo!
                        : event.descriptionEn!,
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                ],

                if (event.category != null && event.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cardAuspicious,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                    ),
                    child: Text(
                      bo
                          ? (event.categoryBo ?? event.category!.replaceAll('_', ' '))
                          : event.category!.replaceAll('_', ' ').toUpperCase(),
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.gold, letterSpacing: bo ? 0 : 1),
                    ),
                  ),

                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(s('SYNC TO CALENDAR', 'ལོ་ཐོར་མཐུན།')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatDateKey(String dateKey, bool bo) {
  try {
    final parts = dateKey.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    if (bo) {
      return '${tibMonthFull(dt.month)} ${toTibNum(dt.day)}། ${toTibNum(dt.year)}';
    }
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    const weekdays = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
        'Saturday', 'Sunday'];
    return '${weekdays[dt.weekday]}, ${months[dt.month]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return dateKey;
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DateRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label:  ',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
        Text(value, style: AppTextStyles.bodySmall.copyWith(color: color)),
      ]);
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _CircleBtn({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          child: Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
        ),
      );
}

class _NotFound extends StatelessWidget {
  final VoidCallback onBack;
  final bool bo;
  const _NotFound({required this.onBack, this.bo = false});

  @override
  Widget build(BuildContext context) => Column(children: [
        AppBar(
          leading: IconButton(
              icon: const Icon(Icons.chevron_left), onPressed: onBack),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        Expanded(
          child: Center(
            child: Text(bo ? 'དུས་ཆེན་མ་རྙེད།' : 'Event not found'),
          ),
        ),
      ]);
}
