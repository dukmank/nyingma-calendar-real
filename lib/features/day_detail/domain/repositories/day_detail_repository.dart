import '../../data/models/day_detail_model.dart';

abstract class DayDetailRepository {
  Future<DayDetailModel?> getDayDetail(String dateKey);
}
