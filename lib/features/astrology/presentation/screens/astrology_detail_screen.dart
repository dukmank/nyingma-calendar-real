import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _CardMeta {
  final String titleEn;
  final String titleBo;
  final String descriptionEn;
  final String descriptionBo;
  final String imageKeyEn;
  final String imageKeyBo;
  final String tableNameEn;
  final String tableNameBo;

  const _CardMeta({
    required this.titleEn,
    required this.titleBo,
    required this.descriptionEn,
    required this.descriptionBo,
    required this.imageKeyEn,
    required this.imageKeyBo,
    required this.tableNameEn,
    required this.tableNameBo,
  });
}

class _DetailPayload {
  final _CardMeta? card;
  final List<Map<String, dynamic>> rows; // raw rows from reference JSON
  final String rawTableTitle;            // title string from reference JSON

  const _DetailPayload({
    required this.card,
    required this.rows,
    required this.rawTableTitle,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _detailProvider =
    FutureProvider.family<_DetailPayload, String>((ref, routeKey) async {
  final cache = ref.read(remoteDataCacheProvider);

  // 1. Load astrology_cards_ref.json to get card metadata
  _CardMeta? cardMeta;
  try {
    final cardsJson =
        await cache.getJson('data/reference/astrology_cards_ref.json');
    final cards =
        (cardsJson['cards'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    Map<String, dynamic>? m;

    // Primary lookup: match by table_en identifier (e.g. "naga_days_tab")
    final wantedTabKey = _tableKeyForRoute(routeKey);
    if (wantedTabKey != null) {
      final found = cards.firstWhere(
        (c) => (c['table_en'] as String?) == wantedTabKey,
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty) m = found;
    }

    // Fallback lookup: match by normalised system_name_en
    // (handles cards with empty table_en, e.g. Parkha)
    if (m == null) {
      final normalised = routeKey.toLowerCase().replaceAll('_', '');
      final found = cards.firstWhere(
        (c) {
          final name = ((c['system_name_en'] as String?) ?? '')
              .toLowerCase()
              .replaceAll(' ', '')
              .replaceAll('-', '');
          return name == normalised;
        },
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty) m = found;
    }

    if (m != null) {
      cardMeta = _CardMeta(
        titleEn:       m['system_name_en']        as String? ?? routeKey,
        titleBo:       m['system_name_bo']        as String? ?? routeKey,
        descriptionEn: m['short_description_en']  as String? ?? '',
        descriptionBo: m['short_description_bo']  as String? ?? '',
        imageKeyEn:    m['main_image_en']          as String? ?? '',
        imageKeyBo:    m['main_image_bo']          as String? ?? '',
        tableNameEn:   m['table_name_en']          as String? ?? '',
        tableNameBo:   m['table_name_bo']          as String? ?? '',
      );
    }
  } catch (_) {}

  // 2. Load per-topic reference JSON for table rows
  final refPath = _refJsonPath(routeKey);
  List<Map<String, dynamic>> rows = [];
  String rawTitle = '';
  if (refPath.isNotEmpty) {
    try {
      final refJson = await cache.getJson(refPath);
      rawTitle = refJson['title'] as String? ?? '';
      rows = ((refJson['rows'] as List?) ?? []).cast<Map<String, dynamic>>();
    } catch (_) {}
  }

  return _DetailPayload(card: cardMeta, rows: rows, rawTableTitle: rawTitle);
});

// ── Route key → astrology_cards_ref table identifier ─────────────────────────

String? _tableKeyForRoute(String key) => switch (key) {
  'naga_days'              => 'naga_days_tab',
  'hair_cutting'           => 'hair_cutting_tab',
  'flag_days'              => 'flag_days_tab',
  'horse_death'            => 'horse_death_tab',
  'restriction_activities' => 'daily_restrictions_tab',
  'fire_rituals'           => 'fire_rituals_tab',
  'torma_offerings'        => 'torma_offerings_tab',
  'empty_vase'             => 'empty_vase_tab',
  'life_force_male'        => 'life_force_male_tab',
  'life_force_female'      => 'life_force_female_tab',
  'eye_twitching'          => 'eye_twitching_tab',
  'fatal_weekdays'         => 'fatal_weekdays_tab',
  'gu_mig'                 => 'gu_mig_tab',
  _ => null,
};

// ── Route key → reference JSON path ──────────────────────────────────────────

String _refJsonPath(String key) => switch (key) {
  'naga_days'              => 'data/reference/naga_days.json',
  'hair_cutting'           => 'data/reference/hair_cutting.json',
  'flag_days'              => 'data/reference/flag_days.json',
  'horse_death'            => 'data/reference/horse_death.json',
  'restriction_activities' => 'data/reference/daily_restrictions.json',
  'fire_rituals'           => 'data/reference/fire_rituals.json',
  'torma_offerings'        => 'data/reference/torma_offerings.json',
  'empty_vase'             => 'data/reference/empty_vase.json',
  'life_force_male'        => 'data/reference/life_force_male.json',
  'life_force_female'      => 'data/reference/life_force_female.json',
  'eye_twitching'          => 'data/reference/eye_twitching.json',
  'fatal_weekdays'         => 'data/reference/fatal_weekdays.json',
  'gu_mig'                 => 'data/reference/gu_mig.json',
  'auspicious_times'       => 'data/reference/auspicious_timing.json',
  _ => '',
};

// ── Fallbacks for keys without a card in astrology_cards_ref.json ─────────────

String _fallbackTitle(String key, bool bo) => switch (key) {
  'auspicious_times' => bo ? 'དུས་ཚོད་མཐུན་མཚམས།' : 'Auspicious Times',
  'parkha'           => bo ? 'སྤར་ཁ།'              : 'Parkha (Pa-Kua)',
  _ => key.replaceAll('_', ' ').toUpperCase(),
};

String _fallbackImageKey(String key, bool bo) => switch (key) {
  'auspicious_times' => 'astrology_auspicious_time',
  'parkha'           => bo ? 'astrology_parkha_bo' : 'astrology_parkha_eng',
  _ => '',
};

// ── Main screen ───────────────────────────────────────────────────────────────

class AstrologyDetailScreen extends ConsumerWidget {
  final String astrologyKey;

  const AstrologyDetailScreen({super.key, required this.astrologyKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider(astrologyKey));
    final bo    = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _buildError(context, bo),
        data: (payload) => _buildContent(context, payload, bo),
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, bool bo) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                bo ? 'གཞི་གྲངས་བཟོ་ཐབས་བྲལ།' : 'Could not load data',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              _CloseButton(bo: bo, onClose: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    _DetailPayload payload,
    bool bo,
  ) {
    final card     = payload.card;
    final title    = bo ? (card?.titleBo ?? _fallbackTitle(astrologyKey, bo))
                        : (card?.titleEn ?? _fallbackTitle(astrologyKey, bo));
    final desc     = bo ? (card?.descriptionBo ?? '')
                        : (card?.descriptionEn ?? '');
    final imageKey = bo ? (card?.imageKeyBo ?? _fallbackImageKey(astrologyKey, bo))
                        : (card?.imageKeyEn ?? _fallbackImageKey(astrologyKey, bo));
    final tblName  = bo ? (card?.tableNameBo ?? payload.rawTableTitle)
                        : (card?.tableNameEn ?? payload.rawTableTitle);

    // Build language-filtered table rows
    final tableResult = _buildTableData(payload.rows, bo);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── AppBar row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Placeholder so title is truly centered
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Thin divider below title bar
          Container(height: 1, color: AppColors.border),

          // ── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Circular hero image ──────────────────────────────
                  if (imageKey.isNotEmpty)
                    GestureDetector(
                      onTap: () => FullScreenImageViewer.open(
                        context,
                        imageKey: imageKey,
                        heroTag: 'astro_img_$astrologyKey',
                      ),
                      child: Center(
                        child: Hero(
                          tag: 'astro_img_$astrologyKey',
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: AppNetworkImage(
                              imageKey: imageKey,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Gold divider ─────────────────────────────────────
                  Center(
                    child: Container(
                      width: 60,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Description ──────────────────────────────────────
                  if (desc.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        desc,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.7,
                        ),
                      ),
                    ),

                  if (desc.isNotEmpty) const SizedBox(height: 20),

                  // ── Table section ────────────────────────────────────
                  if (tableResult.headers.isNotEmpty &&
                      tableResult.rows.isNotEmpty)
                    _DataTable(
                      tableResult: tableResult,
                      tableName: tblName,
                    ),

                  const SizedBox(height: 32),

                  // ── Close button ─────────────────────────────────────
                  _CloseButton(bo: bo, onClose: () => context.pop()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data table widget ─────────────────────────────────────────────────────────

class _DataTable extends StatelessWidget {
  final _TableResult tableResult;
  final String tableName;

  const _DataTable({
    required this.tableResult,
    required this.tableName,
  });

  @override
  Widget build(BuildContext context) {
    final headers = tableResult.headers;
    final rows    = tableResult.rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table name label
        if (tableName.isNotEmpty) ...[
          Text(
            tableName,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Table card
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header row
              Container(
                color: AppColors.primary,
                child: Row(
                  children: headers
                      .map((h) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Text(
                                h,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Data rows
              ...rows.asMap().entries.map((entry) {
                final even = entry.key.isEven;
                final cells = entry.value;
                return Container(
                  color: even ? AppColors.surface : AppColors.surfaceVariant,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cells
                        .map((cell) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Text(
                                  cell,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Close button ──────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final bool bo;
  final VoidCallback onClose;

  const _CloseButton({required this.bo, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onClose,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        bo ? 'བསྡུར།' : 'CLOSE',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Table data extraction — bilingual-aware
// ═══════════════════════════════════════════════════════════════════════════════

class _TableResult {
  final List<String> headers; // display column header strings
  final List<List<String>> rows; // each row is a list of cell strings

  const _TableResult(this.headers, this.rows);

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}

/// Build a language-filtered table from raw JSON rows.
///
/// Three patterns are handled:
///
/// **A) Per-row bilingual suffix** (`naga_days.json`):
///   Each row has keys like `tibetan_month_en` / `tibetan_month_bo`.
///   EN mode: keep `_en` suffix keys.
///   BO mode: keep `_bo` suffix keys.
///
/// **B) Mixed EN+Tibetan-script columns** (`flag_days.json`):
///   Some JSON keys are Tibetan-script, others are Latin.
///   EN mode: Latin keys.  BO mode: Tibetan-script keys.
///
/// **C) Two-block pattern** (all other files):
///   First N rows have Latin values (EN block).
///   Row N contains Tibetan values and acts as the BO header row.
///   Rows N+1 … end are BO data rows.
///   EN mode: rows before split point, headers from key names.
///   BO mode: first Tibetan row → column headers, rest → data.
// Matches snake_case-only strings such as "tibetan_month_en" — used to detect
// column-mapping artifact rows (rows whose values are all field-name strings).
final _snakeCaseOnly = RegExp(r'^[a-z][a-z_0-9]*$');

_TableResult _buildTableData(List<Map<String, dynamic>> raw, bool bo) {
  if (raw.isEmpty) return const _TableResult([], []);

  // ── Pre-filter: remove column-mapping artifact rows ───────────────────────
  // Some source files contain a row whose every string value is a snake_case
  // field name (e.g. "tibetan_month_en", "avoid_flag_days_bo"). These are
  // Excel header-mapping artefacts and must be excluded before processing.
  final cleaned = raw.where((row) {
    final strVals = row.values.whereType<String>().toList();
    if (strVals.isEmpty) return true; // keep rows without string values
    // Drop the row if ALL string values look like snake_case identifiers.
    return !strVals.every((v) => _snakeCaseOnly.hasMatch(v));
  }).toList();

  if (cleaned.isEmpty) return const _TableResult([], []);

  final firstKeys = cleaned.first.keys.toList();

  // ── A) Per-row bilingual suffix ───────────────────────────────────────────
  final hasEnSuffix = firstKeys.any((k) => k.endsWith('_en'));
  final hasBoSuffix = firstKeys.any((k) => k.endsWith('_bo'));

  if (hasEnSuffix && hasBoSuffix) {
    final suffix   = bo ? '_bo' : '_en';
    final baseKeys = firstKeys
        .where((k) => k.endsWith('_en'))
        .map((k) => k.substring(0, k.length - '_en'.length))
        .toList();

    final headers = baseKeys.map(_humaniseKey).toList();
    final rows = cleaned
        .map((row) => baseKeys
            .map((b) => (row['$b$suffix'] ?? row['${b}_en'] ?? '').toString())
            .toList())
        .toList();

    return _TableResult(headers, rows);
  }

  // ── B) Mixed EN + Tibetan-script column keys ──────────────────────────────
  final tibetanKeyList = firstKeys.where(_keyHasTibetan).toList();
  final latinKeyList   = firstKeys.where((k) => !_keyHasTibetan(k)).toList();

  if (tibetanKeyList.isNotEmpty && latinKeyList.isNotEmpty) {
    if (bo) {
      // BO: keep rows where Tibetan columns actually have Tibetan values,
      // filtering out rows where the Tibetan columns contain non-Tibetan data.
      final boRows = cleaned.where((row) => tibetanKeyList.any((k) {
        final v = row[k];
        return v is String && _strHasTibetan(v);
      })).toList();
      final headers = tibetanKeyList.map(_humaniseKey).toList();
      final rows = boRows
          .map((row) =>
              tibetanKeyList.map((k) => (row[k] ?? '').toString()).toList())
          .toList();
      return _TableResult(headers, rows);
    } else {
      // EN: keep rows where the Latin columns do NOT have Tibetan values.
      // This filters out rows where source data has Tibetan numerals in EN columns.
      final enRows = cleaned.where((row) => !latinKeyList.any((k) {
        final v = row[k];
        return v is String && _strHasTibetan(v);
      })).toList();
      final headers = latinKeyList.map(_humaniseKey).toList();
      final rows = enRows
          .map((row) =>
              latinKeyList.map((k) => (row[k] ?? '').toString()).toList())
          .toList();
      return _TableResult(headers, rows);
    }
  }

  // ── C) Two-block pattern ───────────────────────────────────────────────────
  // Find the index of the first row whose values contain Tibetan characters.
  int splitAt = cleaned.length; // default: all rows are EN (no Tibetan block)
  for (var i = 0; i < cleaned.length; i++) {
    if (_rowHasTibetanValues(cleaned[i])) {
      splitAt = i;
      break;
    }
  }

  if (splitAt < cleaned.length) {
    // We have a Tibetan block starting at splitAt.
    if (!bo) {
      // ── EN block: rows 0 … splitAt-1 ──────────────────────────────────
      final enRows = cleaned.sublist(0, splitAt);
      final headers = firstKeys.map(_humaniseKey).toList();
      final rows = enRows
          .map((row) =>
              firstKeys.map((k) => (row[k] ?? '').toString()).toList())
          .toList();
      return _TableResult(headers, rows);
    } else {
      // ── BO block: splitAt = header row, splitAt+1 … = data rows ────────
      final boBlock = cleaned.sublist(splitAt);
      if (boBlock.isEmpty) return const _TableResult([], []);

      // First row of boBlock is the column-header row (Tibetan labels).
      final headerRowValues = boBlock.first;
      final headers = firstKeys
          .map((k) => (headerRowValues[k] ?? _humaniseKey(k)).toString())
          .toList();

      // Remaining rows are the actual data.
      final dataRows = boBlock.sublist(1);
      if (dataRows.isEmpty) return const _TableResult([], []);

      final rows = dataRows
          .map((row) =>
              firstKeys.map((k) => (row[k] ?? '').toString()).toList())
          .toList();
      return _TableResult(headers, rows);
    }
  }

  // ── D) Fully unified (no Tibetan at all) — show as-is ─────────────────────
  final headers = firstKeys.map(_humaniseKey).toList();
  final rows = cleaned
      .map((row) =>
          firstKeys.map((k) => (row[k] ?? '').toString()).toList())
      .toList();
  return _TableResult(headers, rows);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns true if [s] contains any Tibetan-script code point.
bool _strHasTibetan(String s) =>
    s.runes.any((r) => r >= 0x0F00 && r <= 0x0FFF);

/// Returns true if the string key itself contains Tibetan-script characters.
bool _keyHasTibetan(String key) => _strHasTibetan(key);

/// Returns true if any STRING value in the row contains Tibetan characters.
bool _rowHasTibetanValues(Map<String, dynamic> row) {
  for (final v in row.values) {
    if (v is String && _strHasTibetan(v)) return true;
  }
  return false;
}

/// Convert a JSON key to a human-readable header.
/// e.g. `"tibetan_month"` → `"Tibetan Month"`, `"day_1:_short_life"` → `"Day 1 Short Life"`.
String _humaniseKey(String key) {
  return key
      .replaceAll(RegExp(r'[_:\-]+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
