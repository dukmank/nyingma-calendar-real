import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ElementCombinationCard extends StatelessWidget {
  final String combination;
  final String? combinationBo;
  final String? description;
  final String? descriptionBo;
  final bool bo;

  const ElementCombinationCard({
    super.key,
    required this.combination,
    this.combinationBo,
    this.description,
    this.descriptionBo,
    this.bo = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayCombination = bo
        ? (combinationBo?.isNotEmpty == true ? combinationBo! : combination)
        : combination;
    final displayDescription = bo
        ? (descriptionBo?.isNotEmpty == true ? descriptionBo : description)
        : description;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label with left-border accent
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                bo ? 'འབྱུང་བའི་འདུས།' : 'ELEMENT COMBINATION',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.gold,
                  letterSpacing: bo ? 0 : 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bo ? displayCombination : displayCombination.toUpperCase(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: bo ? 0 : 1,
            ),
          ),
          if (displayDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              displayDescription,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
