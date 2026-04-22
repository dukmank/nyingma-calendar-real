import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../data/models/day_detail_model.dart';

class DayHeader extends StatelessWidget {
  final DayDetailModel detail;
  final bool bo;

  const DayHeader({super.key, required this.detail, this.bo = false});

  // ── helpers ────────────────────────────────────────────────────────────────

  /// "15" → "15TH", "1" → "1ST" etc.
  static String _ordinal(String? numStr) {
    final n = int.tryParse(numStr ?? '') ?? 0;
    if (n == 0) return '—';
    final suffix = () {
      final m = n % 100;
      final u = n % 10;
      if (m >= 11 && m <= 13) return 'TH';
      if (u == 1) return 'ST';
      if (u == 2) return 'ND';
      if (u == 3) return 'RD';
      return 'TH';
    }();
    return '$n$suffix';
  }

  @override
  Widget build(BuildContext context) {
    // ── Gregorian ──────────────────────────────────────────────────────────
    final weekdayEn = detail.gregorian.weekdayEn ?? '';
    final weekdayLabel = bo
        ? tibWeekday(weekdayEn.toLowerCase())
        : weekdayEn.toUpperCase();
    final dayNumber = bo
        ? toTibNum(detail.gregorian.day)
        : detail.gregorian.day.toString();

    // ── Auspicious name (title of the day) ────────────────────────────────
    final auspName = bo
        ? (detail.titleBo?.isNotEmpty == true ? detail.titleBo : detail.title)
        : detail.title;

    // ── Arch image ────────────────────────────────────────────────────────
    // Priority chain:
    //   1. detail.imageKey (day-level image, e.g. "fullmoon", "losar")
    //   2. First event whose image_key is non-null
    //   3. null → placeholder
    String? imageKey = detail.imageKey;
    Map<String, dynamic>? primaryEvent;
    for (final evt in detail.inlineEvents) {
      if (imageKey == null && evt['image_key'] != null) {
        imageKey = evt['image_key'] as String?;
      }
      primaryEvent ??= evt; // keep first event for label regardless
    }

    // Label at bottom of arch card
    // Priority: auspicious day name > first event name > null
    final archLabel = auspName ??
        (primaryEvent != null
            ? (bo
                ? (primaryEvent['name_bo'] as String? ??
                   primaryEvent['name_en'] as String?)
                : primaryEvent['name_en'] as String?)
            : null);

    // ── Tibetan info bar ──────────────────────────────────────────────────
    final tibDay   = bo ? (detail.tibetan.day ?? '—') : _ordinal(detail.tibetan.dayEn);
    final animal   = bo
        ? (detail.tibetan.animalMonthBo ?? detail.tibetan.animalMonthEn ?? detail.tibetan.animalYear ?? '—')
        : (detail.tibetan.animalMonthEn ?? detail.tibetan.animalYear ?? '—');
    final monName  = bo
        ? (detail.tibetan.monthNameBo ?? detail.tibetan.monthNameEn ?? '—')
        : (detail.tibetan.monthNameEn ?? '—');
    final monNum   = detail.tibetan.monthEn ?? '—';
    final yearName = bo
        ? (detail.tibetan.yearNameBo ?? detail.tibetan.yearNameEn)
        : detail.tibetan.yearNameEn;
    final yearNum  = bo
        ? (detail.tibetan.year ?? detail.tibetan.yearEn ?? '—')
        : (detail.tibetan.yearEn ?? detail.tibetan.year ?? '—');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Day title area ────────────────────────────────────────────
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Column(
            children: [
              // Weekday
              Text(
                weekdayLabel,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              // Large day number
              Text(
                dayNumber,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 80,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 0.9,
                ),
              ),
              // Auspicious name subtitle
              if (auspName != null) ...[
                const SizedBox(height: 6),
                Text(
                  bo ? auspName : auspName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: bo ? 0 : 2.5,
                    fontFamily: AppTextStyles.labelLarge.fontFamily,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ── 2. Arch image card ───────────────────────────────────────────
        LayoutBuilder(builder: (ctx, constraints) {
          final cardW  = constraints.maxWidth - 56;
          final archR  = cardW / 2;        // makes the top a perfect semicircle
          final cardH  = cardW * 1.15;     // portrait aspect

          return Center(
            child: Container(
              width: cardW,
              height: cardH,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top:    Radius.circular(archR),
                  bottom: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.22),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // Image fills most of the card
                  Expanded(
                    child: imageKey != null
                        ? AppNetworkImage(
                            imageKey: imageKey,
                            width:  cardW,
                            height: cardH,
                            fit: BoxFit.cover,
                          )
                        : _ArchPlaceholder(radius: archR),
                  ),
                  // Bottom label
                  if (archLabel != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: AppColors.gold.withOpacity(0.35)),
                        ),
                      ),
                      child: Text(
                        bo ? archLabel : archLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: bo ? 0 : 2,
                          fontFamily: AppTextStyles.labelLarge.fontFamily,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // ── 3. Dark info bar (DATE | MONTH | YEAR) ───────────────────────
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // DATE
                _InfoCol(
                  label: bo ? 'ཉིན།' : 'DATE',
                  children: [
                    Text(
                      tibDay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                _VDivider(),
                // MONTH
                _InfoCol(
                  label: bo ? 'ཟླ།' : 'MONTH',
                  children: [
                    Text(
                      bo ? animal : animal.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: bo ? 0 : 0.5,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      monName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      monNum,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                _VDivider(),
                // YEAR
                _InfoCol(
                  label: bo ? 'ལོ།' : 'YEAR',
                  children: [
                    if (yearName != null)
                      Text(
                        bo ? yearName : yearName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: bo ? 0 : 0.5,
                          height: 1.2,
                        ),
                      ),
                    Text(
                      yearNum,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── 4. Doubled-day notice ────────────────────────────────────────
        if (detail.tibetanDayDoubled)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppColors.gold),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    bo
                        ? 'ཟླ་འདིར་ཉིན་${detail.tibetan.day ?? detail.tibetan.dayEn ?? ''}པ་གཉིས་ཡོད།'
                        : 'THE ${detail.tibetan.dayEn?.toUpperCase() ?? ''}TH DAY IS DOUBLED THIS MONTH',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.gold),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _ArchPlaceholder extends StatelessWidget {
  final double radius;
  const _ArchPlaceholder({required this.radius});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.cardAuspicious,
        child: Center(
          child: Icon(
            Icons.temple_buddhist_outlined,
            size: radius * 0.35,
            color: AppColors.gold.withOpacity(0.4),
          ),
        ),
      );
}

class _InfoCol extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _InfoCol({required this.label, required this.children});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      );
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white.withOpacity(0.2),
      );
}
