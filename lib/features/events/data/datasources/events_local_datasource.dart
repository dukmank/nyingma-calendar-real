import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/remote_data_cache.dart';

class EventsLocalDataSource {
  final RemoteDataCache _cache;

  EventsLocalDataSource(this._cache);

  /// Updated: manifest-based sync
  Future<Map<String, dynamic>> getEvents() async {
    final path = AppConstants.eventsPath;
    final json = await _cache.getJson(path);
    return json;
  }
}
