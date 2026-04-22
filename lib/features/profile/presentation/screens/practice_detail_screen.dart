import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../domain/entities/practice_entity.dart';
import '../controllers/profile_controller.dart';
import '../../../create_practice/presentation/screens/create_practice_screen.dart';

class PracticeDetailScreen extends ConsumerWidget {
  final PracticeEntity practice;
  const PracticeDetailScreen({super.key, required this.practice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    // Watch provider to get live updates (toggle etc.)
    final profileAsync = ref.watch(profileProvider);
    final _matches = profileAsync.valueOrNull?.practices
        .where((p) => p.id == practice.id);
    final live = (_matches != null && _matches.isNotEmpty)
        ? _matches.first
        : practice;

    String s(String en, String tib) => bo ? tib : en;
    final color = _hexToColor(live.colorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
              background: _HeaderBackground(practice: live, color: color, bo: bo),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mark done today ──────────────────────────────────────
                  _ToggleCard(practice: live, bo: bo, ref: ref),
                  const SizedBox(height: 16),

                  // ── Streak card ──────────────────────────────────────────
                  _StatCard(practice: live, color: color, s: s, bo: bo),
                  const SizedBox(height: 16),

                  // ── Description ──────────────────────────────────────────
                  if ((live.description ?? '').isNotEmpty) ...[
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
                        live.description!,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Last 7 days ──────────────────────────────────────────
                  _SectionHeader(s('Last 7 Days', 'ཉིན་བདུན།')),
                  const SizedBox(height: 8),
                  _Last7DaysRow(practice: live, color: color, bo: bo),
                  const SizedBox(height: 16),

                  // ── History ──────────────────────────────────────────────
                  if (live.completionDates.isNotEmpty) ...[
                    _SectionHeader(s('Completion History', 'གྲུབ་ལོ་རྒྱུས།')),
                    const SizedBox(height: 8),
                    _HistoryGrid(completionDates: live.completionDates, color: color, bo: bo),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, PracticeEntity p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePracticeScreen(existing: p)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      PracticeEntity p, bool bo, String Function(String, String) s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s('Delete Practice', 'སྒྲུབ་པ་བཏང་།')),
        content: Text(s('Delete "${p.title}"?', '"${p.title}" བཏང་བར་གྲུབ་པ་ཡིན་ནམ།')),
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
      ref.read(profileProvider.notifier).deletePractice(p.id);
      Navigator.pop(context);
    }
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ── Header background ──────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final PracticeEntity practice;
  final Color color;
  final bool bo;
  const _HeaderBackground({required this.practice, required this.color, this.bo = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Colored dot + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      practice.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      bo
                        ? 'ཉིན་${toTibNum(practice.streak)} མཐུད་མ།'
                        : '${practice.streak} day streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle card ────────────────────────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  final PracticeEntity practice;
  final bool bo;
  final WidgetRef ref;
  const _ToggleCard({required this.practice, required this.bo, required this.ref});

  @override
  Widget build(BuildContext context) {
    final done = practice.isDoneToday;
    String s(String en, String tib) => bo ? tib : en;

    return GestureDetector(
      onTap: () => ref.read(profileProvider.notifier).togglePractice(practice.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: done
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: done ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done
                        ? s('Done Today!', 'དེ་རིང་གྲུབ་སོང་།')
                        : s('Mark as Done Today', 'དེ་རིང་གྲུབ་བར་ངོས་འཛིན།'),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: done ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (done) ...[
                    const SizedBox(height: 2),
                    Text(
                      s('Tap to unmark', 'ངོས་འཛིན་སྦྱར་ཆོག'),
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? AppColors.primary : AppColors.border,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final PracticeEntity practice;
  final Color color;
  final String Function(String, String) s;
  final bool bo;
  const _StatCard({required this.practice, required this.color, required this.s, this.bo = false});

  @override
  Widget build(BuildContext context) {
    final total = practice.completionDates.length;
    final streak = practice.streak;
    final best = _bestStreak(practice.completionDates);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(
            value: bo ? toTibNum(streak) : '$streak',
            label: s('Day Streak', 'ཉིན་མཐུད་མ།'),
            icon: Icons.local_fire_department,
            iconColor: streak > 0 ? Colors.orange : AppColors.textMuted,
          ),
          _VerticalDivider(),
          _StatItem(
            value: bo ? toTibNum(total) : '$total',
            label: s('Total Done', 'ཚང་མ།'),
            icon: Icons.check_circle_outline,
            iconColor: color,
          ),
          _VerticalDivider(),
          _StatItem(
            value: bo ? toTibNum(best) : '$best',
            label: s('Best Streak', 'ཐོག་མཐར།'),
            icon: Icons.emoji_events_outlined,
            iconColor: const Color(0xFFD4AF37),
          ),
        ],
      ),
    );
  }

  int _bestStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    final sorted = List<String>.from(dates)..sort();
    int best = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 50,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

// ── Last 7 days row ────────────────────────────────────────────────────────────

// Mon-Sun order Tibetan weekday single letters (index 0=Mon, 6=Sun)
const _tibDayLettersMon = ['ཟླ', 'མིག', 'ལྷག', 'ཕུར', 'སངས', 'སྤེན', 'ཉི'];

class _Last7DaysRow extends StatelessWidget {
  final PracticeEntity practice;
  final Color color;
  final bool bo;
  const _Last7DaysRow({required this.practice, required this.color, this.bo = false});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final key =
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final done = practice.completionDates.contains(key);
          const dayNamesEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          final dow = (day.weekday - 1) % 7; // 0=Mon

          return Column(
            children: [
              Text(
                bo ? _tibDayLettersMon[dow] : dayNamesEn[dow],
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: bo ? 8 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: done ? color : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? color : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                bo ? toTibNum(day.day) : '${day.day}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── History grid (mini calendar-style) ────────────────────────────────────────

class _HistoryGrid extends StatelessWidget {
  final List<String> completionDates;
  final Color color;
  final bool bo;
  const _HistoryGrid({required this.completionDates, required this.color, this.bo = false});

  @override
  Widget build(BuildContext context) {
    // Show last 4 months
    final now = DateTime.now();
    final months = List.generate(4, (i) {
      final m = DateTime(now.year, now.month - (3 - i), 1);
      return m;
    });

    return Column(
      children: months.map((monthStart) {
        return _MonthBlock(
          monthStart: monthStart,
          completionDates: completionDates,
          color: color,
          bo: bo,
        );
      }).toList(),
    );
  }
}

// Sun-Sat single Tibetan letters for history grid (index 0=Sun)
const _tibDayLettersSun = ['ཉི', 'ཟླ', 'མིག', 'ལྷག', 'ཕུར', 'སངས', 'སྤེན'];

class _MonthBlock extends StatelessWidget {
  final DateTime monthStart;
  final List<String> completionDates;
  final Color color;
  final bool bo;
  const _MonthBlock({
    required this.monthStart,
    required this.completionDates,
    required this.color,
    this.bo = false,
  });

  @override
  Widget build(BuildContext context) {
    const monthNamesEn = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final firstWeekday = monthStart.weekday % 7; // 0=Sun

    final monthLabel = bo
        ? '${tibMonthFull(monthStart.month)} ${toTibNum(monthStart.year)}'
        : '${monthNamesEn[monthStart.month]} ${monthStart.year}';
    final dowLabels = bo
        ? _tibDayLettersSun
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          // Day-of-week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dowLabels
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted, fontSize: bo ? 7 : 9)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          Wrap(
            children: [
              // Leading empty slots
              ...List.generate(firstWeekday, (_) => const SizedBox(width: 32, height: 32)),
              // Day slots
              ...List.generate(daysInMonth, (i) {
                final day = i + 1;
                final key =
                    '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final done = completionDates.contains(key);
                return SizedBox(
                  width: 32, height: 32,
                  child: Center(
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: done ? color : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          bo ? toTibNum(day) : '$day',
                          style: TextStyle(
                            color: done ? Colors.white : AppColors.textMuted,
                            fontSize: bo ? 9 : 10,
                            fontWeight: done ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
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
