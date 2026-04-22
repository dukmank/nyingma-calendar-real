import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../data/models/day_detail_model.dart';
import '../../domain/entities/astrology_status_entity.dart';

class AstrologyStatusList extends StatelessWidget {
  final List<AstrologyStatusModelItem> items;
  final bool bo;
  final ValueChanged<String>? onItemTap;

  const AstrologyStatusList({
    super.key,
    required this.items,
    this.bo = false,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Red header bar ──────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              bo ? 'རྟགས་རིས།' : 'ASTROLOGY STATUS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(height: 1, color: AppColors.divider),
                _AstrologyRow(
                  item:  item,
                  bo:    bo,
                  onTap: () => onItemTap?.call(item.key),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Single astrology row ──────────────────────────────────────────────────────

class _AstrologyRow extends StatelessWidget {
  final AstrologyStatusModelItem item;
  final bool bo;
  final VoidCallback? onTap;

  const _AstrologyRow({required this.item, required this.bo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label    = bo ? item.labelBo : item.labelEn;
    // In bo mode: prefer Tibetan sub-label; fall back to English only if no bo available.
    // Raw English status codes (e.g. "auspicious", "avoid_medicine") are not shown in bo mode.
    final subLabel = bo
        ? (item.subLabelBo?.isNotEmpty == true ? item.subLabelBo : null)
        : item.subLabelEn;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // ── Thumbnail image (48×48) ───────────────────────────
            _Thumbnail(iconKey: item.iconKey, status: item.status),
            const SizedBox(width: 12),

            // ── Name + status sub-label ──────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleSmall,
                  ),
                  if (subLabel != null && subLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _StatusBadge(status: item.status, label: subLabel),
                  ],
                ],
              ),
            ),

            // ── Right status dot + chevron ───────────────────────
            _StatusDot(status: item.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Thumbnail: actual image when iconKey available, coloured icon fallback ────

class _Thumbnail extends StatelessWidget {
  final String? iconKey;
  final AstrologyStatusType status;

  const _Thumbnail({this.iconKey, required this.status});

  @override
  Widget build(BuildContext context) {
    final bg     = _statusBg(status);
    final fgColor = _statusColor(status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: iconKey != null
            ? AppNetworkImage(
                imageKey: iconKey!,
                width:  48,
                height: 48,
                fit:    BoxFit.cover,
              )
            : Container(
                color: bg,
                child: Icon(
                  _fallbackIcon(iconKey),
                  size: 22,
                  color: fgColor,
                ),
              ),
      ),
    );
  }

  Color _statusColor(AstrologyStatusType s) => switch (s) {
        AstrologyStatusType.auspicious   => AppColors.statusAuspicious,
        AstrologyStatusType.inauspicious => AppColors.statusInauspicious,
        AstrologyStatusType.caution      => AppColors.statusCaution,
        _                                => AppColors.statusNeutral,
      };

  Color _statusBg(AstrologyStatusType s) =>
      _statusColor(s).withOpacity(0.12);

  IconData _fallbackIcon(String? key) => switch (key) {
        null => Icons.circle_outlined,
        _    => Icons.temple_buddhist_outlined,
      };
}

// ── Status badge (text label with coloured background) ────────────────────────

class _StatusBadge extends StatelessWidget {
  final AstrologyStatusType status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final bg    = color.withOpacity(0.10);
    final icon  = switch (status) {
      AstrologyStatusType.auspicious   => '✓',
      AstrologyStatusType.inauspicious => '✕',
      AstrologyStatusType.caution      => '!',
      _                                => '–',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$icon  ${label.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _statusColor(AstrologyStatusType s) => switch (s) {
        AstrologyStatusType.auspicious   => AppColors.statusAuspicious,
        AstrologyStatusType.inauspicious => AppColors.statusInauspicious,
        AstrologyStatusType.caution      => AppColors.statusCaution,
        _                                => AppColors.statusNeutral,
      };
}

// ── Right-side status dot ─────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final AstrologyStatusType status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AstrologyStatusType.auspicious   => AppColors.statusAuspicious,
      AstrologyStatusType.inauspicious => AppColors.statusInauspicious,
      AstrologyStatusType.caution      => AppColors.statusCaution,
      _                                => AppColors.statusNeutral,
    };
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── StatusIcon (re-exported for use in other widgets) ─────────────────────────

class StatusIcon extends StatelessWidget {
  final dynamic status;
  const StatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toString().split('.').last;
    final (icon, color) = switch (s) {
      'auspicious'   => (Icons.check_circle_outline,   AppColors.statusAuspicious),
      'inauspicious' => (Icons.cancel_outlined,        AppColors.statusInauspicious),
      'caution'      => (Icons.warning_amber_outlined, AppColors.statusCaution),
      _              => (Icons.remove_circle_outline,  AppColors.statusNeutral),
    };
    return Icon(icon, size: 18, color: color);
  }
}
