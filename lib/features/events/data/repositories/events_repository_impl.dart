import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_local_datasource.dart';
import '../models/event_model.dart';

class EventsRepositoryImpl implements EventsRepository {
  final EventsLocalDataSource _ds;
  EventsRepositoryImpl(this._ds);

  @override
  Future<List<EventEntity>> getEvents() async {
    final json = await _ds.getEvents();
    final raw = (json['events'] as List? ?? []).cast<Map<String, dynamic>>();
    return raw.map(EventModel.fromJson).toList();
  }
}
