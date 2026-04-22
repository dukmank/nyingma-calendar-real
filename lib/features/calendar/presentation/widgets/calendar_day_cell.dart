import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../domain/entities/calendar_day_entity.dart';

class CalendarDayCell extends StatelessWidget {
  final CalendarDayEntity day;
  final bool isSelected;
  final bool bo;
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.bo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = day.isToday;
    // New JSON uses full weekday names: "Sunday", "Monday", etc.
    final isSunday = day.weekdayEn == 'Sunday' || day.weekdayEn == 'Sun';

    Color textColor;
    Color bgColor;
    if (isToday) {
      bgColor = AppColors.calendarToday;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = AppColors.calendarSelected;
      textColor = AppColors.primary;
    } else if (day.isExtremelyAuspicious) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = Colors.transparent;
      textColor = isSunday ? AppColors.calendarWeekend : AppColors.textPrimary;
    }

    // Day number: Arabic or Tibetan numeral
    final dayLabel = bo ? toTibNum(day.day) : day.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: isSelected && !isToday
              ? Border.all(color: AppColors.gold, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gregorian number (Arabic or Tibetan)
            Text(
              dayLabel,
              style: AppTextStyles.calendarDayNumber.copyWith(
                color: textColor,
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            // Lunar day: Arabic numeral in English mode, Tibetan script in Tibetan mode
            if ((bo ? day.tibetanDay : day.tibetanDayEn) != null)
              Text(
                bo ? day.tibetanDay! : day.tibetanDayEn!,
                style: bo
                    ? AppTextStyles.calendarGoldNumber.copyWith(
                        color: isToday ? Colors.white70 : AppColors.gold,
                      )
                    : TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: isToday ? Colors.white70 : AppColors.textMuted,
                        height: 1,
                      ),
              ),
            // Dot indicators
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (day.isAuspicious || day.isExtremelyAuspicious)
                  _dot(const Color(0xFFE53935)), // red = auspicious
                if (day.isInauspicious)
                  _dot(const Color(0xFF212121)), // black = inauspicious
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
