import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/shared_preferences_provider.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/entities/practice_entity.dart';
import '../../domain/entities/user_event_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../states/profile_state.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final local = ProfileLocalDataSource(prefs);
  // Pass the user's auth token here once you have it, e.g.:
  // final token = ref.watch(authTokenProvider);
  final remote = ProfileRemoteDataSource(
    api: ApiService(authToken: null),  // swap null → 'Bearer <token>'
    userId: 'local',                   // swap 'local' → real user ID from Auth
  );
  return ProfileRepositoryImpl(local: local, remote: remote);
});

// ── Notifier ─────────────────────────────────────────────────────────────────

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<ProfileState> build() async {
    final profile   = await _repo.getProfile();
    final practices = await _repo.getPractices();
    final events    = await _repo.getUserEvents();
    final stats     = ProfileStatsEntity.compute(
      practices: practices,
      events: events,
    );
    // Seed with defaults if this is the very first launch
    if (practices.isEmpty) await _seedDefaultPractices();
    return ProfileState(
      profile: profile,
      practices: practices.isEmpty ? await _repo.getPractices() : practices,
      events: events,
      stats: stats,
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> updateProfile(UserProfileEntity updated) async {
    await _repo.saveProfile(updated);
    state = state.whenData(
      (s) => s.copyWith(profile: updated),
    );
  }

  // ── Practices ─────────────────────────────────────────────────────────────

  Future<void> togglePractice(String id) async {
    try {
      final updated = await _repo.togglePracticeToday(id);
      state = state.whenData((s) {
        final practices = s.practices
            .map((p) => p.id == id ? updated : p)
            .toList();
        return s.withPractices(practices);
      });
    } catch (e) {
      // Practice not found — refresh
      await _refresh();
    }
  }

  Future<void> addPractice(PracticeEntity practice) async {
    await _repo.savePractice(practice);
    await _refresh();
  }

  Future<void> updatePractice(PracticeEntity practice) async {
    await _repo.savePractice(practice);
    await _refresh();
  }

  Future<void> deletePractice(String id) async {
    await _repo.deletePractice(id);
    state = state.whenData(
      (s) => s.withPractices(s.practices.where((p) => p.id != id).toList()),
    );
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<void> addEvent(UserEventEntity event) async {
    await _repo.saveUserEvent(event);
    await _refresh();
  }

  Future<void> updateEvent(UserEventEntity event) async {
    await _repo.saveUserEvent(event);
    await _refresh();
  }

  Future<void> deleteEvent(String id) async {
    await _repo.deleteUserEvent(id);
    state = state.whenData(
      (s) => s.withEvents(s.events.where((e) => e.id != id).toList()),
    );
  }

  // ── Clear all data ────────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    await _repo.clearAllData();
    // Rebuild state from scratch — will be a clean guest + no practices/events
    ref.invalidateSelf();
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  Future<void> sync() async {
    state = state.whenData((s) => s.copyWith(isSyncing: true));
    try {
      await _repo.pullFromServer();
      await _refresh();
      state = state.whenData((s) => s.copyWith(isSyncing: false, clearSyncError: true));
    } catch (e) {
      state = state.whenData(
        (s) => s.copyWith(isSyncing: false, lastSyncError: e.toString()),
      );
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final practices = await _repo.getPractices();
    final events    = await _repo.getUserEvents();
    final stats     = ProfileStatsEntity.compute(
      practices: practices,
      events: events,
    );
    state = state.whenData(
      (s) => s.copyWith(practices: practices, events: events, stats: stats),
    );
  }

  /// Seeds three default practices so a new user isn't staring at an empty
  /// profile screen.
  Future<void> _seedDefaultPractices() async {
    final now = DateTime.now();
    final defaults = [
      PracticeEntity(
        id: 'ngondro',
        title: 'Ngöndro Foundations',
        colorHex: '#8B1A1A',
        createdAt: now,
        updatedAt: now,
      ),
      PracticeEntity(
        id: 'morning_sadhana',
        title: 'Morning Sadhana',
        colorHex: '#888888',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      PracticeEntity(
        id: 'guru_yoga',
        title: 'Guru Yoga',
        colorHex: '#888888',
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final p in defaults) {
      await _repo.savePractice(p);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
