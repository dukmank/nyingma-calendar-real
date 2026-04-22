import '../../domain/entities/user_profile_entity.dart';
import '../../domain/entities/practice_entity.dart';
import '../../domain/entities/user_event_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';

/// Immutable snapshot of all user profile data shown on the profile screen.
class ProfileState {
  final UserProfileEntity profile;
  final List<PracticeEntity> practices;
  final List<UserEventEntity> events;
  final ProfileStatsEntity stats;
  /// True while a background server sync is in progress.
  final bool isSyncing;
  /// Non-null if the last sync attempt failed.
  final String? lastSyncError;

  const ProfileState({
    required this.profile,
    required this.practices,
    required this.events,
    required this.stats,
    this.isSyncing = false,
    this.lastSyncError,
  });

  factory ProfileState.empty() => ProfileState(
        profile: UserProfileEntity.guest(),
        practices: const [],
        events: const [],
        stats: const ProfileStatsEntity(),
      );

  ProfileState copyWith({
    UserProfileEntity? profile,
    List<PracticeEntity>? practices,
    List<UserEventEntity>? events,
    ProfileStatsEntity? stats,
    bool? isSyncing,
    String? lastSyncError,
    bool clearSyncError = false,
  }) =>
      ProfileState(
        profile: profile ?? this.profile,
        practices: practices ?? this.practices,
        events: events ?? this.events,
        stats: stats ?? this.stats,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSyncError:
            clearSyncError ? null : (lastSyncError ?? this.lastSyncError),
      );

  ProfileStatsEntity _recomputeStats(
    List<PracticeEntity> p,
    List<UserEventEntity> e,
  ) =>
      ProfileStatsEntity.compute(practices: p, events: e);

  /// Returns a new state with [practices] replaced and stats recomputed.
  ProfileState withPractices(List<PracticeEntity> p) => copyWith(
        practices: p,
        stats: _recomputeStats(p, events),
        clearSyncError: false,
      );

  /// Returns a new state with [events] replaced and stats recomputed.
  ProfileState withEvents(List<UserEventEntity> e) => copyWith(
        events: e,
        stats: _recomputeStats(practices, e),
        clearSyncError: false,
      );
}
