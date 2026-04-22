import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/practice_entity.dart';
import '../controllers/profile_controller.dart';
import '../../../create_practice/presentation/screens/create_practice_screen.dart';
import 'practice_detail_screen.dart';
import 'user_event_detail_screen.dart';

class MyPracticesScreen extends ConsumerWidget {
  const MyPracticesScreen({super.key});

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
        title: Text(s('My Practices', 'སྒྲུབ་པ།'), style: AppTextStyles.headlineLarge),
      ),
      body: profileAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) => _Body(practices: state.practices, bo: bo),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final List<PracticeEntity> practices;
  final bool bo;

  const _Body({required this.practices, required this.bo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String s(String en, String tib) => bo ? tib : en;

    // Today's practices = all (show completed first)
    final todayList = [...practices]
      ..sort((a, b) => a.isDoneToday == b.isDoneToday ? 0 : (a.isDoneToday ? -1 : 1));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Section header ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        s("Today's Practices", 'དེ་རིང་གི་སྒྲུབ་པ།'),
                        style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (todayList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            s('No practices yet. Add one below.',
                              'སྒྲུབ་པ་མེད། ཞབས་འཇོག་གནང་།'),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...todayList.map((p) => _PracticeItem(
                            practice: p,
                            bo: bo,
                            onTap: () => _openDetail(context, p),
                            onToggle: () =>
                                ref.read(profileProvider.notifier).togglePractice(p.id),
                            onEdit: () => _openEdit(context, p),
                            onDelete: () => _confirmDelete(context, ref, p, bo),
                          )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Add New Practice button ────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16,
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
                    s('Add New Practice', 'སྒྲུབ་པ་གསར་པ།'),
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

  Future<void> _openDetail(BuildContext context, PracticeEntity p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PracticeDetailScreen(practice: p)),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePracticeScreen()),
    );
  }

  Future<void> _openEdit(BuildContext context, PracticeEntity p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePracticeScreen(existing: p)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, PracticeEntity p, bool bo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(bo ? 'བཏང་བར་གྲུབ་པ།' : 'Delete Practice'),
        content: Text(bo
            ? '"${p.title}" བཏང་བར་གྲུབ་པ་ཡིན་ནམ།'
            : 'Delete "${p.title}"?'),
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
    if (ok == true) ref.read(profileProvider.notifier).deletePractice(p.id);
  }
}

// ── Practice item with swipe-to-reveal ───────────────────────────────────────

class _PracticeItem extends StatefulWidget {
  final PracticeEntity practice;
  final bool bo;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PracticeItem({
    required this.practice,
    required this.bo,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PracticeItem> createState() => _PracticeItemState();
}

class _PracticeItemState extends State<_PracticeItem> {
  bool _swiped = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.practice;
    final color = _hexToColor(p.colorHex);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left to reveal, right to close
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            setState(() => _swiped = true);
          } else if (details.primaryVelocity! > 200) {
            setState(() => _swiped = false);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        child: Stack(
          children: [
            // ── Background action buttons ──────────────────────────
            if (_swiped)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    GestureDetector(
                      onTap: () {
                        setState(() => _swiped = false);
                        widget.onEdit();
                      },
                      child: Container(
                        width: 72,
                        color: const Color(0xFF3B82F6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                            const SizedBox(height: 4),
                            Text(widget.bo ? 'བཅོས།' : 'Edit',
                                style: const TextStyle(color: Colors.white, fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    // Delete button
                    GestureDetector(
                      onTap: () {
                        setState(() => _swiped = false);
                        widget.onDelete();
                      },
                      child: Container(
                        width: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                            const SizedBox(height: 4),
                            Text(widget.bo ? 'བཏང་།' : 'Delete',
                                style: const TextStyle(color: Colors.white, fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Foreground item row ────────────────────────────────
            AnimatedSlide(
              offset: _swiped ? const Offset(-0.37, 0) : Offset.zero,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: _swiped ? () => setState(() => _swiped = false) : widget.onTap,
                child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  // Colored dot
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: p.isDoneToday ? color : color.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      p.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: p.isDoneToday
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: p.isDoneToday
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                  // Checkbox
                  GestureDetector(
                    onTap: widget.onToggle,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: p.isDoneToday ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: p.isDoneToday
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: p.isDoneToday
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                  ),
                ]),
              ),
            ),
          ),
          ],
        ),
      ),
    );
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
