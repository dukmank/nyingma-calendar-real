import '../entities/event_entity.dart';

abstract class EventsRepository {
  Future<List<EventEntity>> getEvents();
}
