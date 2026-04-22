import '../repositories/events_repository.dart';

class GetEvents {
  final EventsRepository repository;

  GetEvents(this.repository);

  Future<void> call() {
    return repository.getEvents();
  }
}
