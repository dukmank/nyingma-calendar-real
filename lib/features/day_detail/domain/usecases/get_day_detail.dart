import '../repositories/day_detail_repository.dart';
import '../../data/models/day_detail_model.dart';

class GetDayDetail {
  final DayDetailRepository _repository;

  GetDayDetail(this._repository);

  Future<DayDetailModel?> call(String dateKey) =>
      _repository.getDayDetail(dateKey);
}
