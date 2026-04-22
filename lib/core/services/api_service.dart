import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Thin HTTP wrapper around the Nyingmapa Calendar REST API.
///
/// All public methods throw [ApiException] on non-2xx responses.
/// The [authToken] is set after the user logs in; pass it in every
/// request so the server can identify the user.
///
/// Usage (in a repository or datasource):
/// ```dart
/// final api = ApiService(authToken: 'Bearer <token>');
/// final json = await api.get('/users/me/practices');
/// ```
class ApiService {
  ApiService({this.authToken});

  final String? authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': authToken!,
      };

  Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  // ── GET ──────────────────────────────────────────────────────────────────

  Future<dynamic> get(String path) async {
    final res = await http
        .get(_uri(path), headers: _headers)
        .timeout(AppConstants.apiTimeout);
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  // ── POST ─────────────────────────────────────────────────────────────────

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(AppConstants.apiTimeout);
    _checkStatus(res);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  // ── PATCH ────────────────────────────────────────────────────────────────

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http
        .patch(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(AppConstants.apiTimeout);
    _checkStatus(res);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  // ── DELETE ───────────────────────────────────────────────────────────────

  Future<void> delete(String path) async {
    final res = await http
        .delete(_uri(path), headers: _headers)
        .timeout(AppConstants.apiTimeout);
    _checkStatus(res);
  }

  // ── Error handling ────────────────────────────────────────────────────────

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String? message;
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        message = body?['message'] as String?;
      } catch (_) {}
      throw ApiException(
        statusCode: res.statusCode,
        message: message ?? 'HTTP ${res.statusCode}: ${res.reasonPhrase}',
      );
    }
  }
}

// ── API Exception ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden    => statusCode == 403;
  bool get isNotFound     => statusCode == 404;
  bool get isServerError  => statusCode >= 500;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
