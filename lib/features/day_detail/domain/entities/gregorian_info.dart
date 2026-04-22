class GregorianInfo {
  final int day;
  final int month;
  final int year;

  final String? weekdayEn;
  final String? monthLabelEn;

  const GregorianInfo({
    required this.day,
    required this.month,
    required this.year,
    this.weekdayEn,
    this.monthLabelEn,
  });
}