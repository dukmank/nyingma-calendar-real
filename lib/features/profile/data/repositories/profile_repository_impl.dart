import 'dart:math';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/entities/practice_entity.dart';
import '../../domain/entities/user_event_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';
import '../models/practice_model.dart';
import '../models/user_event_model.dart';

/// **Offline-first** implementation of [ProfileRepository].
///
/// Every write goes to [local] immediately and returns.  The remote push is
/// fire-and-forget so the UI never waits for network.  If the device is
/// offline the sync simply doesn't happen; it will retry next time
/// [syncToServer] or [pullFromServer] is called.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required this.local,
    required this.remote,
  });

  final ProfileLocalDataSource local;
  final ProfileRemoteDataSource remote;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _newId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0,8)}-${hex.substring(8,12)}-'
        '${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';
  }

  // ── User profile ──────────────────────────────────────────────────────────

  @override
  Future<UserProfileEntity> getProfile() async {
    return local.getProfile() ?? UserProfileEntity.guest();
  }

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    final model = UserProfileModel.fromEntity(profile);
    await local.saveProfile(model);
    // Fire-and-forget remote push
    _silently(() => remote.pushProfile(model));
  }

  // ── Practices ─────────────────────────────────────────────────────────────

  @override
  Future<List<PracticeEntity>> getPractices() async {
    return local.getPractices();
  }

  @override
  Future<void> savePractice(PracticeEntity practice) async {
    // Assign id if new
    final entity = practice.id.isEmpty
        ? practice.copyWith()  // id cannot be set via copyWith; use _newId below
        : practice;
    final id = entity.id.isEmpty ? _newId() : entity.id;
    final finalEntity = PracticeEntity(
      id: id,
      title: entity.title,
      description: entity.description,
      colorHex: entity.colorHex,
      completionDates: entity.completionDates,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
    final models = local.getPractices();
    final idx = models.indexWhere((m) => m.id == id);
    final model = PracticeModel.fromEntity(finalEntity);
    if (idx >= 0) {
      models[idx] = model;
    } else {
      models.add(model);
    }
    await local.savePractices(models);
    _silently(() => remote.upsertPractice(model));
  }

  @override
  Future<void> deletePractice(String id) async {
    final models = local.getPractices()..removeWhere((m) => m.id == id);
    await local.savePractices(models);
    _silently(() => remote.deletePractice(id));
  }

  @override
  Future<PracticeEntity> togglePracticeToday(String id) async {
    final models = local.getPractices();
    final idx = models.indexWhere((m) => m.id == id);
    if (idx < 0) throw StateError('Practice $id not found');
    final toggled = models[idx].withTodayToggled();
    models[idx] = PracticeModel.fromEntity(toggled);
    await local.savePractices(models);
    final today = _todayKey();
    if (toggled.isDoneToday) {
      _silently(() => remote.markPracticeComplete(id, today));
    }
    _silently(() => remote.upsertPractice(models[idx]));
    return toggled;
  }

  // ── User events ───────────────────────────────────────────────────────────

  @override
  Future<List<UserEventEntity>> getUserEvents() async {
    return local.getUserEvents();
  }

  @override
  Future<void> saveUserEvent(UserEventEntity event) async {
    final id = event.id.isEmpty ? _newId() : event.id;
    final finalEvent = UserEventEntity(
      id: id,
      title: event.title,
      content: event.content,
      dateKey: event.dateKey,
      timeOfDay: event.timeOfDay,
      lunarDay: event.lunarDay,
      lunarLabel: event.lunarLabel,
      imageKey: event.imageKey,
      repeatType: event.repeatType,
      reminderMinutes: event.reminderMinutes,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
    final models = local.getUserEvents();
    final idx = models.indexWhere((m) => m.id == id);
    final model = UserEventModel.fromEntity(finalEvent);
    if (idx >= 0) {
      models[idx] = model;
    } else {
      models.add(model);
    }
    // Sort ascending by dateKey
    models.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    await local.saveUserEvents(models);
    _silently(() => remote.upsertUserEvent(model));
  }

  @override
  Future<void> deleteUserEvent(String id) async {
    final models = local.getUserEvents()..removeWhere((m) => m.id == id);
    await local.saveUserEvents(models);
    _silently(() => remote.deleteUserEvent(id));
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  @override
  Future<void> syncToServer() async {
    try {
      final profile = local.getProfile();
      if (profile != null) await remote.pushProfile(profile);

      for (final p in local.getPractices()) {
        await remote.upsertPractice(p);
      }
      for (final e in local.getUserEvents()) {
        await remote.upsertUserEvent(e);
      }
      await local.saveLastSyncedAt(DateTime.now());
    } catch (_) {
      // Offline — fail silently; next sync attempt will retry.
    }
  }

  @override
  Future<void> pullFromServer() async {
    try {
      final remoteProfile = await remote.fetchProfile();
      if (remoteProfile != null) await local.saveProfile(remoteProfile);

      final remotePractices = await remote.fetchPractices();
      if (remotePractices.isNotEmpty) {
        await local.savePractices(remotePractices);
      }

      final remoteEvents = await remote.fetchUserEvents();
      if (remoteEvents.isNotEmpty) {
        await local.saveUserEvents(remoteEvents);
      }

      await local.saveLastSyncedAt(DateTime.now());
    } catch (_) {
      // Offline — keep local data, no-op.
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  // ── Clear all ─────────────────────────────────────────────────────────────

  @override
  Future<void> clearAllData() async {
    await local.clearAll();
    // Fire-and-forget: tell the server to delete this user's data too.
    // Implement remote.deleteAllUserData() when the endpoint exists.
    // _silently(() => remote.deleteAllUserData());
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Run [fn] in the background; swallow any error so network issues
  /// never surface to the UI.
  void _silently(Future<void> Function() fn) {
    fn().catchError((_) {});
  }
}
