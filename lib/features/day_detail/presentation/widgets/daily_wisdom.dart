import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DailyWisdomCard extends StatelessWidget {
  final String wisdom;
  final String? author;
  final bool bo;

  const DailyWisdomCard({
    super.key,
    required this.wisdom,
    this.author,
    this.bo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardAuspicious,
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
                bo ? 'གདམས་ངག' : 'DAILY WISDOM',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.gold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"$wisdom"',
            style: AppTextStyles.quote,
          ),
          if (author != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— $author',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
