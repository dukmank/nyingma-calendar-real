import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../models/news_post_model.dart';

class NewsRemoteDataSource {
  final http.Client _client;
  NewsRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'apikey': AppConstants.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
    'Content-Type': 'application/json',
  };

  String get _base => '${AppConstants.supabaseUrl}/rest/v1';

  Future<List<NewsPostModel>> getPublishedNews({String? category}) async {
    if (AppConstants.supabaseUrl.isEmpty) {
      throw Exception('Supabase chưa cấu hình — chạy: source dart_define.sh && flutter run \$DART_DEFINES');
    }
    String q = 'status=eq.published&order=published_at.desc&select=*';
    if (category != null) q += '&category=eq.$category';
    final url = Uri.parse('$_base/news_posts?$q');
    final res = await _client.get(url, headers: _headers).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Supabase ${res.statusCode}: ${res.body}');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => NewsPostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NewsPostModel?> getNewsById(String id) async {
    final url = Uri.parse('$_base/news_posts?id=eq.$id&status=eq.published&select=*&limit=1');
    final res = await _client.get(url, headers: _headers).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Supabase ${res.statusCode}');
    final List data = jsonDecode(res.body);
    if (data.isEmpty) return null;
    return NewsPostModel.fromJson(data.first as Map<String, dynamic>);
  }
}
