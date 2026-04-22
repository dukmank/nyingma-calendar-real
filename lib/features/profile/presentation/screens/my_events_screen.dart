import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/user_event_entity.dart';
import '../controllers/profile_controller.dart';
import '../../../create_event/presentation/screens/create_event_screen.dart';
import 'user_event_detail_screen.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bo = ref.watch(languageProvider);
    final profileAsync = ref.watch(profileProvider);
    String s(String en, String tib) => bo ? tib : en;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(s('My Events', 'ང་ཡི་དུས་ཆེན།'), style: AppTextStyles.headlineLarge),
      ),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) => _Body(events: state.events, bo: bo),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final List<UserEventEntity> events;
  final bool bo;

  const _Body({required this.events, required this.bo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String s(String en, String tib) => bo ? tib : en;

    // Sort by date ascending
    final sorted = [...events]..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    return Column(
      children: [
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_outlined,
                          size: 56, color: AppColors.textMuted.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        s('No events yet', 'དུས་ཆེན་མེད།'),
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _EventRow(
                    event: sorted[i],
                    bo: bo,
                    onTap: () => _openDetail(context, sorted[i]),
                    onDelete: () => _confirmDelete(context, ref, sorted[i], bo),
                  ),
                ),
        ),

        // ── Add New Event button ───────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16,
              MediaQuery.of(context).padding.bottom + 16),
          child: GestureDetector(
            onTap: () => _openCreate(context),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    s('Add New Event', 'དུས་ཆེན་གསར་པ།'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDetail(BuildContext context, UserEventEntity e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserEventDetailScreen(event: e)),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
  }

  Future<void> _openEdit(BuildContext context, UserEventEntity e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEventScreen(existing: e)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, UserEventEntity e, bool bo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(bo ? 'བཏང་བར་གྲུབ་པ།' : 'Delete Event'),
        content: Text(bo ? '"${e.title}" བཏང་བར་གྲུབ་པ་ཡིན་ནམ།'
            : 'Delete "${e.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(bo ? 'མེད།' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(bo ? 'བཏང་།' : 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(profileProvider.notifier).deleteEvent(e.id);
  }
}

// ── Event row ─────────────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final UserEventEntity event;
  final bool bo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EventRow({
    required this.event,
    required this.bo,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (bo) {
        return '${tibMonthFull(dt.month)} ${toTibNum(dt.day)}། ${toTibNum(dt.year)}';
      }
      const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(event.dateKey);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          // ── Image ────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: event.imageKey != null && event.imageKey!.isNotEmpty
                ? AppNetworkImage(
                    imageKey: event.imageKey!,
                    width: 60, height: 60,
                    fit: BoxFit.cover,
                  )
                : _PagodaPlaceholder(size: 60),
          ),
          const SizedBox(width: 14),

          // ── Text ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (event.lunarLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.lunarLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

// ── Pagoda placeholder for user-created events ────────────────────────────────

class _PagodaPlaceholder extends StatelessWidget {
  final double size;
  const _PagodaPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF3A1208).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            Icons.temple_buddhist_outlined,
            color: AppColors.primary.withOpacity(0.6),
            size: size * 0.5,
          ),
        ),
      );
}
