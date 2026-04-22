import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../models/calendar_day_model.dart';

class CalendarLocalDatasource {
  final RemoteDataCache _cache;

  CalendarLocalDatasource(this._cache);

  Future<CalendarMonthModel> getMonth(int year, int month) async {
    final path = AppConstants.calendarPath(year, month);
    try {
      final json = await _cache.getJson(path);
      return CalendarMonthModel.fromJson(json);
    } catch (_) {
      // Remote unavailable or month not yet published — fall back to grid
      return _emptyMonth(year, month);
    }
  }

  CalendarMonthModel _emptyMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final days = <CalendarDayModel>[];
    for (var d = firstDay; !d.isAfter(lastDay); d = d.add(const Duration(days: 1))) {
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      days.add(CalendarDayModel(
        dateKey: key,
        day: d.day,
        month: d.month,
        year: d.year,
        weekdayEn: weekdays[(d.weekday - 1) % 7],
        isToday: key == todayKey,
      ));
    }

    return CalendarMonthModel(
      year: year,
      month: month,
      monthLabelEn: monthNames[month],
      tibetanMonthEn: '',
      tibetanMonthBo: '',
      yearLabelEn: '',
      yearLabelBo: '',
      days: days,
    );
  }
}
