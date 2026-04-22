import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/router/route_names.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

// ── Search result model ───────────────────────────────────────────────────────

enum _ResultType { event, practice, userEvent }

class _SearchResult {
  final _ResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String? dateKey;
  final IconData icon;
  final Color iconColor;

  const _SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.dateKey,
    required this.icon,
    required this.iconColor,
  });
}

// ── Search provider ───────────────────────────────────────────────────────────

class _SearchNotifier extends StateNotifier<List<_SearchResult>> {
  final RemoteDataCache _cache;
  _SearchNotifier(this._cache) : super([]);

  List<Map<String, dynamic>> _eventsData = [];

  Future<void> load() async {
    if (_eventsData.isNotEmpty) return;
    try {
      final json = await _cache.getJson(AppConstants.eventsPath);
      _eventsData = (json['events'] as List).cast<Map<String, dynamic>>();
    } catch (_) {}
  }

  void search(String query, bool bo, List<dynamic> practices,
      List<dynamic> userEvents) {
    if (query.trim().isEmpty) {
      state = [];
      return;
    }
    final q = query.toLowerCase();
    final results = <_SearchResult>[];

    // ── Calendar events ────────────────────────────────────────────────────
    // New JSON: name_en/name_bo, details_en, category_en, date
    for (final e in _eventsData) {
      final titleEn = (e['name_en'] as String? ?? '').toLowerCase();
      final titleBo = (e['name_bo'] as String? ?? '').toLowerCase();
      final descEn  = (e['details_en'] as String? ?? '').toLowerCase();
      final category = (e['category_en'] as String? ?? '').toLowerCase();
      if (titleEn.contains(q) ||
          titleBo.contains(q) ||
          descEn.contains(q) ||
          category.contains(q)) {
        results.add(_SearchResult(
          type: _ResultType.event,
          id: e['id'] as String? ?? '',
          title: bo
              ? (e['name_bo'] as String? ?? e['name_en'] as String? ?? '')
              : (e['name_en'] as String? ?? ''),
          // Actual field: 'date_key' (no gregorian_display or tibetan_display in events.json)
          subtitle: e['date_key'] as String? ?? '',
          dateKey: e['date_key'] as String?,
          icon: Icons.temple_buddhist_outlined,
          iconColor: AppColors.gold,
        ));
      }
    }

    // ── User's personal practices ──────────────────────────────────────────
    for (final p in practices) {
      final title = (p.title as String? ?? '').toLowerCase();
      if (title.contains(q)) {
        results.add(_SearchResult(
          type: _ResultType.practice,
          id: p.id as String,
          title: p.title as String,
          subtitle: bo ? 'སྒྲུབ་རིམ།' : 'Personal Practice',
          icon: Icons.self_improvement,
          iconColor: Color(
              int.parse((p.colorHex as String).replaceFirst('#', '0xFF'))),
        ));
      }
    }

    // ── User's saved events ────────────────────────────────────────────────
    for (final e in userEvents) {
      final title = e.title.toLowerCase();
      final content = e.content.toLowerCase();
      if (title.contains(q) || content.contains(q)) {
        // skip entries that are saved community events (content starts with 'calendar:')
        if (e.content.startsWith('calendar:')) continue;
        results.add(_SearchResult(
          type: _ResultType.userEvent,
          id: e.id as String,
          title: e.title as String,
          subtitle: bo
              ? (e.lunarLabel as String? ?? e.dateKey as String? ?? '')
              : (e.dateKey as String? ?? ''),
          dateKey: e.dateKey as String?,
          icon: Icons.bookmark_outline,
          iconColor: AppColors.primary,
        ));
      }
    }

    state = results;
  }
}

final _searchProvider =
    StateNotifierProvider.autoDispose<_SearchNotifier, List<_SearchResult>>(
  (ref) => _SearchNotifier(ref.read(remoteDataCacheProvider)),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_searchProvider.notifier).load();
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final bo = ref.read(languageProvider);
    final profileState = ref.read(profileProvider).valueOrNull;
    ref.read(_searchProvider.notifier).search(
          value,
          bo,
          profileState?.practices ?? [],
          profileState?.events ?? [],
        );
  }

  void _onResultTap(_SearchResult result, bool bo) {
    switch (result.type) {
      case _ResultType.event:
        if (result.id.isNotEmpty) context.push(RouteNames.eventDetailOf(result.id));
      case _ResultType.practice:
        // Navigate to profile to show the practice
        context.go(RouteNames.profile);
      case _ResultType.userEvent:
        if (result.dateKey != null && result.dateKey!.isNotEmpty) {
          context.push(RouteNames.dayDetailOf(result.dateKey!));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bo = ref.watch(languageProvider);
    String s(String en, String tib) => bo ? tib : en;
    final results = ref.watch(_searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: s('Search events, practices…', 'དུས་ཆེན་དང་སྒྲུབ་རིམ་བཙལ།'),
            hintStyle:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            isDense: true,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textMuted,
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _controller.text.isEmpty
          ? _EmptyState(bo: bo)
          : results.isEmpty
              ? _NoResults(query: _controller.text, bo: bo)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: AppColors.border,
                  ),
                  itemBuilder: (ctx, i) => _ResultTile(
                    result: results[i],
                    bo: bo,
                    onTap: () => _onResultTap(results[i], bo),
                  ),
                ),
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final bool bo;
  final VoidCallback onTap;

  const _ResultTile(
      {required this.result, required this.bo, required this.onTap});

  String get _typeLabel {
    switch (result.type) {
      case _ResultType.event:
        return bo ? 'དུས་ཆེན།' : 'Event';
      case _ResultType.practice:
        return bo ? 'སྒྲུབ་རིམ།' : 'Practice';
      case _ResultType.userEvent:
        return bo ? 'ང་ཡི་དུས་ཆེན།' : 'My Event';
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: result.iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(result.icon, size: 20, color: result.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(result.subtitle,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: result.iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _typeLabel,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: result.iconColor, fontSize: 10),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}

// ── Empty / no-results states ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool bo;
  const _EmptyState({required this.bo});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 56, color: AppColors.border),
            const SizedBox(height: 14),
            Text(
              bo ? 'དུས་ཆེན་དང་སྒྲུབ་རིམ་བཙལ།' : 'Search events & practices',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
}

class _NoResults extends StatelessWidget {
  final String query;
  final bool bo;
  const _NoResults({required this.query, required this.bo});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.border),
            const SizedBox(height: 14),
            Text(
              bo ? '"$query" མ་རྙེད།' : 'No results for "$query"',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
