import '../../domain/repositories/day_detail_repository.dart';
import '../datasources/day_detail_local_datasource.dart';
import '../models/day_detail_model.dart';

class DayDetailRepositoryImpl implements DayDetailRepository {
  final DayDetailLocalDatasource _datasource;

  DayDetailRepositoryImpl(this._datasource);

  @override
  Future<DayDetailModel?> getDayDetail(String dateKey) =>
      _datasource.getDayDetail(dateKey);
}
