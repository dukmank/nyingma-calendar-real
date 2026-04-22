import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/direction_entity.dart';

class DirectionSection extends StatelessWidget {
  final List<DirectionEntity> directions;

  const DirectionSection({super.key, required this.directions});

  @override
  Widget build(BuildContext context) {
    if (directions.isEmpty) return const SizedBox.shrink();
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
          Text('DIRECTIONS', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted, letterSpacing: 2)),
          const SizedBox(height: 12),
          ...directions.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined, size: 16, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(d.labelEn, style: AppTextStyles.titleSmall),
                    const Spacer(),
                    if (d.direction != null)
                      Text(d.direction!.toUpperCase(), style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
