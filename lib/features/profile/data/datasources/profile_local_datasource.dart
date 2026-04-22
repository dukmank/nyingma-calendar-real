import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_profile_model.dart';
import '../models/practice_model.dart';
import '../models/user_event_model.dart';

/// All local persistence for the profile feature.
///
/// Uses [SharedPreferences] (injected) so this class is fully synchronous
/// from the caller's perspective — no async waiting on every read after init.
class ProfileLocalDataSource {
  ProfileLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  // ── User profile ──────────────────────────────────────────────────────────

  UserProfileModel? getProfile() {
    final raw = _prefs.getString(AppConstants.spUserProfile);
    if (raw == null) return null;
    try {
      return UserProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfileModel model) async {
    await _prefs.setString(
      AppConstants.spUserProfile,
      jsonEncode(model.toJson()),
    );
  }

  // ── Practices ─────────────────────────────────────────────────────────────

  List<PracticeModel> getPractices() {
    final raw = _prefs.getString(AppConstants.spPractices);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(PracticeModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePractices(List<PracticeModel> models) async {
    await _prefs.setString(
      AppConstants.spPractices,
      jsonEncode(models.map((m) => m.toJson()).toList()),
    );
  }

  // ── User events ───────────────────────────────────────────────────────────

  List<UserEventModel> getUserEvents() {
    final raw = _prefs.getString(AppConstants.spUserEvents);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(UserEventModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUserEvents(List<UserEventModel> models) async {
    await _prefs.setString(
      AppConstants.spUserEvents,
      jsonEncode(models.map((m) => m.toJson()).toList()),
    );
  }

  // ── Sync metadata ─────────────────────────────────────────────────────────

  DateTime? getLastSyncedAt() {
    final raw = _prefs.getString(AppConstants.spLastSyncedAt);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastSyncedAt(DateTime dt) async {
    await _prefs.setString(AppConstants.spLastSyncedAt, dt.toIso8601String());
  }

  // ── Nuke ──────────────────────────────────────────────────────────────────

  /// Removes every key written by this datasource.
  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(AppConstants.spUserProfile),
      _prefs.remove(AppConstants.spPractices),
      _prefs.remove(AppConstants.spUserEvents),
      _prefs.remove(AppConstants.spLastSyncedAt),
    ]);
  }
}
