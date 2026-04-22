import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/event_entity.dart';
import '../controllers/events_controller.dart';

const _months = [
  'All', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// Tibetan month names — index 0 = "All", 1–12 = Jan–Dec Gregorian
const _monthsBo = [
  'ཚང་མ།', 'ཟླ་དང་པོ།', 'ཟླ་གཉིས་པ།', 'ཟླ་གསུམ་པ།',
  'ཟླ་བཞི་པ།', 'ཟླ་ལྔ་པ།', 'ཟླ་དྲུག་པ།', 'ཟླ་བདུན་པ།',
  'ཟླ་བརྒྱད་པ།', 'ཟླ་དགུ་པ།', 'ཟླ་བཅུ་པ།', 'ཟླ་བཅུ་གཅིག་པ།', 'ཟླ་བཅུ་གཉིས་པ།',
];

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  String _selectedMonth = 'All';
  String? _selectedCategory;
  bool _showFilterMenu = false;

  static const _categories = ['Birthday', 'Parinirvana', 'Annual Festival', 'Odisha Dudjom Vihara'];

  List<EventEntity> _filtered(List<EventEntity> events) {
    var list = events;
    if (_selectedMonth != 'All') {
      list = list.where((e) {
        if (e.dateKey.length < 7) return false;
        final m = int.tryParse(e.dateKey.substring(5, 7)) ?? 0;
        return _months[m] == _selectedMonth;
      }).toList();
    }
    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }
    return list;
  }

  Map<String, List<EventEntity>> _grouped(List<EventEntity> events) {
    final result = <String, List<EventEntity>>{};
    for (final e in _filtered(events)) {
      final m = e.dateKey.length >= 7 ? (int.tryParse(e.dateKey.substring(5, 7)) ?? 0) : 0;
      final month = m >= 1 && m <= 12 ? _months[m] : 'Other';
      result.putIfAbsent(month, () => []).add(e);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bo = ref.watch(languageProvider);
    String s(String en, String tib) => bo ? tib : en;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () { if (_showFilterMenu) setState(() => _showFilterMenu = false); },
        behavior: HitTestBehavior.translucent,
        child: Stack(children: [
          CustomScrollView(
            slivers: [
              // ── AppBar ─────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                titleSpacing: 16,
                title: Text(
                  s('Yearly Events', 'ལོ་རེའི་དུས་ཆེན།'),
                  style: AppTextStyles.headlineMedium,
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.tune_outlined,
                      color: _selectedCategory != null ? AppColors.primary : AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _showFilterMenu = !_showFilterMenu),
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: _MonthChips(
                      selected: _selectedMonth,
                      onSelect: (m) => setState(() { _selectedMonth = m; _showFilterMenu = false; }),
                      bo: bo,
                    ),
                  ),
                ),
              ),

              eventsAsync.when(
                loading: () => const SliverFillRemaining(child: AppLoading()),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(s('Could not load events.\nPlease check your connection.',
                               'དུས་ཆེན་མི་ཐོབ།\nར་སྤྲོད་བལྟས་རོགས།'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.invalidate(eventsProvider),
                          child: Text(s('Retry', 'ཡང་བསྐྱར།')),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (events) {
                  final grouped = _grouped(events);
                  if (grouped.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(s('No events found', 'དུས་ཆེན་མེད།'),
                            style: AppTextStyles.bodyMedium),
                      ),
                    );
                  }
                  final groupKeys = grouped.keys.toList();
                  final totalItems = grouped.values.fold<int>(0, (sum, l) => sum + l.length + 1);
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        int pos = 0;
                        for (final monthKey in groupKeys) {
                          final items = grouped[monthKey]!;
                          if (i == pos) return _MonthHeader(month: monthKey, bo: bo);
                          pos++;
                          for (final evt in items) {
                            if (i == pos) {
                              return _EventCard(
                                event: evt,
                                bo: bo,
                                onTap: () => context.push(RouteNames.eventDetailOf(evt.id)),
                              );
                            }
                            pos++;
                          }
                        }
                        return null;
                      },
                      childCount: totalItems,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),

          // ── Filter dropdown overlay ──────────────────────────────
          if (_showFilterMenu)
            Positioned(
              top: 104,
              right: 12,
              child: _FilterMenu(
                categories: _categories,
                selected: _selectedCategory,
                bo: bo,
                onSelect: (cat) => setState(() {
                  _selectedCategory = cat;
                  _showFilterMenu = false;
                }),
                onClear: () => setState(() {
                  _selectedCategory = null;
                  _showFilterMenu = false;
                }),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Month chip row ────────────────────────────────────────────────────────────

class _MonthChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool bo;

  const _MonthChips({required this.selected, required this.onSelect, this.bo = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _months.length,
          itemBuilder: (context, i) {
            final m = _months[i];
            final label = bo ? _monthsBo[i] : m;
            final active = m == selected;
            return GestureDetector(
              onTap: () => onSelect(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      );
}

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final String month;
  final bool bo;
  const _MonthHeader({required this.month, this.bo = false});

  @override
  Widget build(BuildContext context) {
    // Convert English month name → Tibetan equivalent for the header
    final idx = _months.indexOf(month);
    final label = (bo && idx >= 0) ? _monthsBo[idx] : month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        bo ? label : label.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primary, letterSpacing: bo ? 0 : 2, fontSize: 11),
      ),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventEntity event;
  final bool bo;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.bo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = bo ? (event.titleBo.isNotEmpty ? event.titleBo : event.titleEn) : event.titleEn;
    final dateKey = event.dateKey;

    String dateStr = dateKey;
    if (dateKey.length == 10) {
      try {
        final dt = DateTime.parse(dateKey);
        if (bo) {
          dateStr = '${tibMonthFull(dt.month)} ${toTibNum(dt.day)}། ${toTibNum(dt.year)}';
        } else {
          const monthAbbr = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          dateStr = '${monthAbbr[dt.month]} ${dt.day}, ${dt.year}';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: event.imageKey != null
                ? AppNetworkImage(imageKey: event.imageKey!, width: 64, height: 64, fit: BoxFit.cover)
                : Container(
                    width: 64, height: 64,
                    color: AppColors.cardAuspicious,
                    child: const Icon(Icons.temple_buddhist_outlined, color: AppColors.gold, size: 28),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
              style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(dateStr,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            if ((bo ? (event.categoryBo ?? event.category) : event.category) != null) ...[
              const SizedBox(height: 2),
              Text(
                (bo ? (event.categoryBo ?? event.category) : event.category)!,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ])),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

// ── Filter menu overlay ───────────────────────────────────────────────────────

// Tibetan translations for the hardcoded category names
const _categoryBo = {
  'Birthday':             'གནས་སྐབས།',
  'Parinirvana':          'མྱ་ངན་ལས་འདས།',
  'Annual Festival':      'ལོ་རེའི་དུས་ཆེན།',
  'Odisha Dudjom Vihara': 'ཨོ་རི་ས་བདུད་འཇོམས་ཡང་གུ།',
};

class _FilterMenu extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final bool bo;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  const _FilterMenu({
    required this.categories,
    required this.selected,
    this.bo = false,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black26,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Text(
                  bo ? 'རིགས་ལ་གཏག་བཤེར།' : 'FILTER BY TYPE',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMuted, fontSize: 10, letterSpacing: bo ? 0 : 1)),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ...categories.map((cat) {
                final label = bo ? (_categoryBo[cat] ?? cat) : cat;
                return GestureDetector(
                  onTap: () => onSelect(cat),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected == cat ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                    ),
                    child: Text(label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: selected == cat ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: selected == cat ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }),
              const Divider(height: 1, color: AppColors.divider),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    bo ? 'གཏག་བཤེར་སེལ།' : 'Clear Filters',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
}
