import 'package:flutter/material.dart'; // includes Colors
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/tibetan_utils.dart';
import '../../data/models/calendar_day_model.dart';
import 'calendar_day_cell.dart';

class CalendarGrid extends StatelessWidget {
  final CalendarMonthModel monthData;
  final String? selectedDateKey;
  final bool bo;
  final ValueChanged<String>? onDateSelected;

  const CalendarGrid({
    super.key,
    required this.monthData,
    this.selectedDateKey,
    this.bo = false,
    this.onDateSelected,
  });

  // English single-letter headers (Sun→Sat)
  static const _weekdaysEn = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(monthData.year, monthData.month, 1);
    // weekday: Mon=1 ... Sun=7; we want Sun=0
    final startOffset = firstDay.weekday % 7;

    final headers = bo ? tibWeekdayLetters : _weekdaysEn;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Column(
        children: [
          // Weekday headers
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (i) => Expanded(
                child: Center(
                  child: Text(
                    headers[i],
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: bo ? 9 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )),
            ),
          ),
          // Days grid
          _buildGrid(startOffset),
        ],
      ),
    );
  }

  Widget _buildGrid(int startOffset) {
    final cells = <Widget>[];

    // Leading empty cells
    for (var i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (final day in monthData.days) {
      cells.add(CalendarDayCell(
        day: day,
        isSelected: day.dateKey == selectedDateKey,
        bo: bo,
        onTap: () => onDateSelected?.call(day.dateKey),
      ));
    }

    // Trailing empty cells to fill grid
    final remainder = cells.length % 7;
    if (remainder != 0) {
      for (var i = 0; i < 7 - remainder; i++) {
        cells.add(const SizedBox());
      }
    }

    final rows = <Widget>[];
    for (var r = 0; r < cells.length; r += 7) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            children: cells
                .sublist(r, r + 7)
                .map((c) => Expanded(child: SizedBox(height: 46, child: c)))
                .toList(),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
