import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../data/datasources/calendar_local_datasource.dart';
import '../../data/models/calendar_day_model.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/usecases/get_month_calendar.dart';

// Providers
final calendarDatasourceProvider = Provider(
  (ref) => CalendarLocalDatasource(ref.watch(remoteDataCacheProvider)),
);

final calendarRepositoryProvider = Provider((ref) =>
    CalendarRepositoryImpl(ref.watch(calendarDatasourceProvider)));

final getMonthCalendarProvider = Provider((ref) =>
    GetMonthCalendar(ref.watch(calendarRepositoryProvider)));

// State
class CalendarState {
  final int year;
  final int month;
  final String? selectedDateKey;
  final CalendarMonthModel? monthData;
  final bool isLoading;
  final String? error;

  const CalendarState({
    required this.year,
    required this.month,
    this.selectedDateKey,
    this.monthData,
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    int? year,
    int? month,
    String? selectedDateKey,
    bool clearSelectedDate = false,   // pass true to explicitly null out selectedDateKey
    CalendarMonthModel? monthData,
    bool? isLoading,
    String? error,
  }) =>
      CalendarState(
        year: year ?? this.year,
        month: month ?? this.month,
        selectedDateKey: clearSelectedDate ? null : (selectedDateKey ?? this.selectedDateKey),
        monthData: monthData ?? this.monthData,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class CalendarController extends StateNotifier<CalendarState> {
  final GetMonthCalendar _getMonth;

  CalendarController(this._getMonth)
      : super(CalendarState(
          year: DateTime.now().year,
          month: DateTime.now().month,
        )) {
    loadMonth(state.year, state.month);
  }

  Future<void> loadMonth(int year, int month) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _getMonth(year, month);
      state = state.copyWith(monthData: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void goToPreviousMonth() {
    var m = state.month - 1;
    var y = state.year;
    if (m < 1) {
      m = 12;
      y--;
    }
    state = state.copyWith(year: y, month: m);
    loadMonth(y, m);
  }

  void goToNextMonth() {
    var m = state.month + 1;
    var y = state.year;
    if (m > 12) {
      m = 1;
      y++;
    }
    state = state.copyWith(year: y, month: m);
    loadMonth(y, m);
  }

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      year: now.year,
      month: now.month,
      clearSelectedDate: true,   // reset to today so the hero shows today
    );
    loadMonth(now.year, now.month);
  }

  void selectDate(String dateKey) {
    state = state.copyWith(selectedDateKey: dateKey);
  }
}

final calendarControllerProvider =
    StateNotifierProvider<CalendarController, CalendarState>((ref) {
  return CalendarController(ref.watch(getMonthCalendarProvider));
});
