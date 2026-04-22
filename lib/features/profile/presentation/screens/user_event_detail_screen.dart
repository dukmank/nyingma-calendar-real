import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/user_event_entity.dart';
import '../controllers/profile_controller.dart';
import '../../../create_event/presentation/screens/create_event_screen.dart';

class UserEventDetailScreen extends ConsumerWidget {
  final UserEventEntity event;
  const UserEventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    // Watch for live updates (e.g. after editing)
    final profileAsync = ref.watch(profileProvider);
    final _matches = profileAsync.valueOrNull?.events
        .where((e) => e.id == event.id);
    final live = (_matches != null && _matches.isNotEmpty) ? _matches.first : event;

    String s(String en, String tib) => bo ? tib : en;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                onPressed: () => _openEdit(context, live),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                onPressed: () => _confirmDelete(context, ref, live, bo, s),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _EventHeader(event: live),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date card ────────────────────────────────────────────
                  _DateCard(event: live, s: s, bo: bo),
                  const SizedBox(height: 14),

                  // ── Time + Reminder row ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: s('Time', 'དུས་ཚོད།'),
                          value: live.timeOfDay,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.notifications_outlined,
                          label: s('Reminder', 'དྲན་སྐུལ།'),
                          value: live.reminderMinutes < 0
                              ? s('None', 'མེད།')
                              : _reminderLabel(live.reminderMinutes, s),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Repeat ───────────────────────────────────────────────
                  if (live.repeatType != 'never') ...[
                    _InfoChip(
                      icon: Icons.repeat_rounded,
                      label: s('Repeat', 'ཡང་བསྐྱར།'),
                      value: _repeatLabel(live.repeatType, s),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Content ──────────────────────────────────────────────
                  if (live.content.isNotEmpty &&
                      !live.content.startsWith('calendar:')) ...[
                    _SectionHeader(s('Notes', 'གཞི་ལུང་།')),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        live.content,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Created at ───────────────────────────────────────────
                  Text(
                    s('Added ${_formatDate(live.createdAt.toIso8601String().split('T').first)}',
                      'བར་མཐུད་ ${_formatDate(live.createdAt.toIso8601String().split('T').first)}'),
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, UserEventEntity e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEventScreen(existing: e)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      UserEventEntity e, bool bo, String Function(String, String) s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s('Delete Event', 'དུས་ཆེན་བཏང་།')),
        content: Text(s('Delete "${e.title}"?',
            '"${e.title}" བཏང་བར་གྲུབ་པ་ཡིན་ནམ།')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s('Cancel', 'མེད།')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s('Delete', 'བཏང་།'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(profileProvider.notifier).deleteEvent(e.id);
      Navigator.pop(context);
    }
  }

  String _reminderLabel(int minutes, String Function(String, String) s) {
    if (minutes == 0) return s('At time', 'དུས་ཚོད་ལ།');
    if (minutes < 60) return s('$minutes min before', 'སྐར་མ་${toTibNum(minutes)} སྔོན།');
    final h = minutes ~/ 60;
    return s('$h hr before', 'ཆུ་ཚོད་${toTibNum(h)} སྔོན།');
  }

  String _repeatLabel(String type, String Function(String, String) s) {
    switch (type) {
      case 'daily': return s('Daily', 'ཉིན་རེ།');
      case 'weekly': return s('Weekly', 'གཟའ་ཕར།');
      case 'monthly': return s('Monthly', 'ཟླ་ཕར།');
      case 'yearly': return s('Yearly', 'ལོ་ཕར།');
      default: return s('Never', 'མེད།');
    }
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateKey;
    }
  }
}

// ── Event header ───────────────────────────────────────────────────────────────

class _EventHeader extends StatelessWidget {
  final UserEventEntity event;
  const _EventHeader({required this.event});

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imageKey != null && event.imageKey!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image or pagoda gradient
        if (hasImage)
          AppNetworkImage(
            imageKey: event.imageKey!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  Color.lerp(AppColors.primary, Colors.black, 0.4)!,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.temple_buddhist_outlined,
                color: Colors.white.withOpacity(0.3),
                size: 80,
              ),
            ),
          ),

        // Gradient overlay (always)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),

        // Title at bottom
        Positioned(
          left: 20, right: 20, bottom: 20,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (event.lunarLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.lunarLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Date card ─────────────────────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  final UserEventEntity event;
  final String Function(String, String) s;
  final bool bo;
  const _DateCard({required this.event, required this.s, this.bo = false});

  @override
  Widget build(BuildContext context) {
    String formatDate(String dateKey) {
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

    final dateStr = formatDate(event.dateKey);
    final parts = event.dateKey.split('-');
    final dayStr = parts.length > 2 ? parts[2] : '?';
    final month = parts.length > 1 ? parts[1] : '?';
    final day = dayStr;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Calendar icon widget
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bo
                    ? tibMonthShort(int.tryParse(month) ?? 1)
                    : _monthAbbr(int.tryParse(month) ?? 1),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: bo ? 8 : 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  bo ? toTibNum(int.tryParse(dayStr) ?? 1) : day,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700),
                ),
                if (event.lunarLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.lunarLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int m) {
    const abbr = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return m >= 1 && m <= 12 ? abbr[m] : '?';
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted, fontSize: 10)),
                Text(value,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      );
}
