import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';

class AuspiciousLocalDataSource {
  final RemoteDataCache _cache;

  AuspiciousLocalDataSource(this._cache);

  /// Updated: manifest-based sync
  Future<Map<String, dynamic>> getAuspicious() async {
    final path = AppConstants.auspiciousPath;
    final json = await _cache.getJson(path);
    return json;
  }
}
