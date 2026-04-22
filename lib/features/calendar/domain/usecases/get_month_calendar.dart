import '../repositories/calendar_repository.dart';
import '../../data/models/calendar_day_model.dart';

class GetMonthCalendar {
  final CalendarRepository _repository;

  GetMonthCalendar(this._repository);

  Future<CalendarMonthModel> call(int year, int month) =>
      _repository.getMonth(year, month);
}
