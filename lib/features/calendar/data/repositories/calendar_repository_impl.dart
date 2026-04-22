import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';
import '../models/calendar_day_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDatasource _datasource;

  CalendarRepositoryImpl(this._datasource);

  @override
  Future<CalendarMonthModel> getMonth(int year, int month) =>
      _datasource.getMonth(year, month);
}
