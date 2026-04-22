import '../../../../core/services/api_service.dart';
import '../models/user_profile_model.dart';
import '../models/practice_model.dart';
import '../models/user_event_model.dart';

/// REST API datasource for the profile feature.
///
/// All endpoints follow the pattern:
///   GET    /users/{userId}/profile
///   PATCH  /users/{userId}/profile
///   GET    /users/{userId}/practices
///   POST   /users/{userId}/practices
///   PATCH  /users/{userId}/practices/{id}
///   DELETE /users/{userId}/practices/{id}
///   POST   /users/{userId}/practices/{id}/complete
///   GET    /users/{userId}/events
///   POST   /users/{userId}/events
///   DELETE /users/{userId}/events/{id}
///
/// Currently all methods are **stubs** that succeed silently.
/// To activate server sync:
///   1. Point [AppConstants.apiBaseUrl] to your backend.
///   2. Implement Firebase Auth (or JWT) and pass the token to [ApiService].
///   3. Uncomment the real API calls below and remove the stub returns.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource({required this.api, required this.userId});

  final ApiService api;
  final String userId;

  String get _base => '/users/$userId';

  // ── User profile ──────────────────────────────────────────────────────────

  Future<UserProfileModel?> fetchProfile() async {
    // --- STUB: uncomment when backend is ready ---
    // final json = await api.get('$_base/profile');
    // return UserProfileModel.fromJson(json as Map<String, dynamic>);
    return null;
  }

  Future<void> pushProfile(UserProfileModel model) async {
    // await api.patch('$_base/profile', model.toJson());
  }

  // ── Practices ─────────────────────────────────────────────────────────────

  Future<List<PracticeModel>> fetchPractices() async {
    // final json = await api.get('$_base/practices') as List<dynamic>;
    // return json.cast<Map<String,dynamic>>().map(PracticeModel.fromJson).toList();
    return [];
  }

  Future<void> upsertPractice(PracticeModel model) async {
    // await api.post('$_base/practices', model.toJson());
  }

  Future<void> deletePractice(String id) async {
    // await api.delete('$_base/practices/$id');
  }

  Future<void> markPracticeComplete(String id, String dateKey) async {
    // await api.post('$_base/practices/$id/complete', {'dateKey': dateKey});
  }

  // ── User events ───────────────────────────────────────────────────────────

  Future<List<UserEventModel>> fetchUserEvents() async {
    // final json = await api.get('$_base/events') as List<dynamic>;
    // return json.cast<Map<String,dynamic>>().map(UserEventModel.fromJson).toList();
    return [];
  }

  Future<void> upsertUserEvent(UserEventModel model) async {
    // await api.post('$_base/events', model.toJson());
  }

  Future<void> deleteUserEvent(String id) async {
    // await api.delete('$_base/events/$id');
  }
}
