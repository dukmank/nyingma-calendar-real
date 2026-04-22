import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../data/datasources/day_detail_local_datasource.dart';
import '../../data/models/day_detail_model.dart';
import '../../data/repositories/day_detail_repository_impl.dart';
import '../../domain/usecases/get_day_detail.dart';

final dayDetailDatasourceProvider = Provider(
  (ref) => DayDetailLocalDatasource(ref.watch(remoteDataCacheProvider)),
);

final dayDetailRepositoryProvider = Provider((ref) =>
    DayDetailRepositoryImpl(ref.watch(dayDetailDatasourceProvider)));

final getDayDetailProvider = Provider((ref) =>
    GetDayDetail(ref.watch(dayDetailRepositoryProvider)));

final dayDetailProvider =
    FutureProvider.family<DayDetailModel?, String>((ref, dateKey) {
  return ref.watch(getDayDetailProvider).call(dateKey);
});
