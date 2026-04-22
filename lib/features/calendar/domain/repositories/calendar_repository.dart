import '../../data/models/calendar_day_model.dart';

abstract class CalendarRepository {
  Future<CalendarMonthModel> getMonth(int year, int month);
}
