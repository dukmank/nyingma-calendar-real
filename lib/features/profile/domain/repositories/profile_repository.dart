import '../entities/user_profile_entity.dart';
import '../entities/practice_entity.dart';
import '../entities/user_event_entity.dart';

/// Contract between domain and data layers for all user-generated content.
///
/// Implementations are expected to be **offline-first**: every method should
/// return/persist to local storage immediately and then sync with the server
/// in the background.  Callers should never need to know whether the device
/// is online.
abstract class ProfileRepository {
  // ── User profile ──────────────────────────────────────────────────────────

  /// Returns the stored profile, or a sensible [UserProfileEntity.guest] default.
  Future<UserProfileEntity> getProfile();

  /// Persists the profile locally and queues a server PATCH.
  Future<void> saveProfile(UserProfileEntity profile);

  // ── Practices ─────────────────────────────────────────────────────────────

  Future<List<PracticeEntity>> getPractices();

  /// Upserts a practice by [id] (insert if new, replace if existing).
  Future<void> savePractice(PracticeEntity practice);

  Future<void> deletePractice(String id);

  /// Toggles today's completion for the given practice and persists.
  Future<PracticeEntity> togglePracticeToday(String id);

  // ── User events ───────────────────────────────────────────────────────────

  Future<List<UserEventEntity>> getUserEvents();

  /// Upserts a user event by [id].
  Future<void> saveUserEvent(UserEventEntity event);

  Future<void> deleteUserEvent(String id);

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Push all locally-pending changes to the server.
  /// Silently succeeds if offline; never throws to the caller.
  Future<void> syncToServer();

  /// Fetch latest data from the server and overwrite local cache.
  Future<void> pullFromServer();

  /// Wipe **all** locally-stored user data (profile, practices, events).
  /// Also attempts to notify the server; failure is swallowed.
  Future<void> clearAllData();
}
