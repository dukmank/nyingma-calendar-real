class CalendarDayEntity {
  final String dateKey; 

  final int day;
  final int month;
  final int year;

  final String? weekdayEn;
  final String? weekdayBo;

  final String? tibetanDay;    // Tibetan script numeral (e.g. "༢༨")
  final String? tibetanDayEn;  // Arabic numeral string  (e.g. "28")
  final String? tibetanMonth;
  final String? tibetanYear;

  final bool isToday;
  final bool isSelected;

  final bool hasEvents;
  final bool hasAstrology;

  final bool isAuspicious;
  final bool isInauspicious;
  final bool isExtremelyAuspicious;

  const CalendarDayEntity({
    required this.dateKey,
    required this.day,
    required this.month,
    required this.year,
    this.weekdayEn,
    this.weekdayBo,
    this.tibetanDay,
    this.tibetanDayEn,
    this.tibetanMonth,
    this.tibetanYear,
    this.isToday = false,
    this.isSelected = false,
    this.hasEvents = false,
    this.hasAstrology = false,
    this.isAuspicious = false,
    this.isInauspicious = false,
    this.isExtremelyAuspicious = false,
  });
}