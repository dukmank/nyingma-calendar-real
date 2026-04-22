import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EventPreviewList extends StatelessWidget {
  final List<String> eventIds;
  final ValueChanged<String>? onEventTap;

  const EventPreviewList({super.key, required this.eventIds, this.onEventTap});

  @override
  Widget build(BuildContext context) {
    if (eventIds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("TODAY'S EVENTS", style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1.5)),
        ),
        ...eventIds.map((id) => GestureDetector(
              onTap: () => onEventTap?.call(id),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event, color: AppColors.gold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(id, style: AppTextStyles.titleSmall)),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
