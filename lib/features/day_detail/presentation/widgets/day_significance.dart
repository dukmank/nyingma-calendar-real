import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DaySignificanceCard extends StatelessWidget {
  final String? title;
  final String? titleBo;
  final String? significanceEn;
  final String? significanceBo;
  final bool bo;

  const DaySignificanceCard({
    super.key,
    this.title,
    this.titleBo,
    this.significanceEn,
    this.significanceBo,
    this.bo = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = bo
        ? (titleBo?.isNotEmpty == true ? titleBo : title)
        : title;
    final displayText = bo
        ? (significanceBo?.isNotEmpty == true ? significanceBo : significanceEn)
        : significanceEn;

    if (displayText == null && displayTitle == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Red header bar ──────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              bo ? 'ཉིན་གྱི་གཞུང་།' : 'DAY SIGNIFICANCE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (displayTitle != null) ...[
                  Text(
                    displayTitle,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Significance text
                if (displayText != null) ...[
                  Text(
                    displayText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.65,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
