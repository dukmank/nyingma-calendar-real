import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/remote_data_cache.dart';
import '../../data/datasources/events_local_datasource.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/events_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final eventsDatasourceProvider = Provider<EventsLocalDataSource>((ref) =>
    EventsLocalDataSource(ref.watch(remoteDataCacheProvider)));

final eventsRepositoryProvider = Provider<EventsRepository>((ref) =>
    EventsRepositoryImpl(ref.watch(eventsDatasourceProvider)));

/// All calendar events from B2 — cached after first load.
final eventsProvider = FutureProvider<List<EventEntity>>((ref) =>
    ref.watch(eventsRepositoryProvider).getEvents());

/// Single event by ID — derived from eventsProvider.
final eventByIdProvider =
    FutureProvider.family<EventEntity?, String>((ref, id) async {
  final events = await ref.watch(eventsProvider.future);

  // Primary: exact ID match
  final byId = events.where((e) => e.id == id);
  if (byId.isNotEmpty) return byId.first;

  // Fallback: inline IDs are "YYYY-MM-DD-{index}"
  final parts = id.split('-');
  if (parts.length == 4) {
    final dateKey = '${parts[0]}-${parts[1]}-${parts[2]}';
    final idx = int.tryParse(parts[3]) ?? 0;
    final dateEvents = events.where((e) => e.dateKey == dateKey).toList();
    if (idx < dateEvents.length) return dateEvents[idx];
  }

  return null;
});
