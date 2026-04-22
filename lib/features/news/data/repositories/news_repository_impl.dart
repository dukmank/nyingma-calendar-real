import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/news_post_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../datasources/news_remote_datasource.dart';
import '../models/news_post_model.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource _remote;
  static const _cacheTtl = Duration(hours: 1);

  NewsRepositoryImpl({NewsRemoteDataSource? remote})
      : _remote = remote ?? NewsRemoteDataSource();

  @override
  Future<List<NewsPostEntity>> getPublishedNews({String? category}) async {
    // Try cache first (only for full list, no category filter)
    if (category == null) {
      final cached = await _readCache();
      if (cached != null) return cached;
    }

    final posts = await _remote.getPublishedNews(category: category);

    // Write to cache (full list only)
    if (category == null) await _writeCache(posts);

    return posts;
  }

  @override
  Future<NewsPostEntity?> getNewsById(String id) => _remote.getNewsById(id);

  // ── Cache helpers ─────────────────────────────────────────────────────────

  Future<List<NewsPostModel>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAtStr = prefs.getString(AppConstants.spNewsCachedAt);
      if (cachedAtStr == null) return null;
      final cachedAt = DateTime.tryParse(cachedAtStr);
      if (cachedAt == null) return null;
      if (DateTime.now().difference(cachedAt) > _cacheTtl) return null;

      final json = prefs.getString(AppConstants.spNewsCache);
      if (json == null) return null;
      final List data = jsonDecode(json);
      return data.map((e) => NewsPostModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<NewsPostModel> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(posts.map((p) => p.toJson()).toList());
      await prefs.setString(AppConstants.spNewsCache, json);
      await prefs.setString(AppConstants.spNewsCachedAt, DateTime.now().toIso8601String());
    } catch (_) {}
  }
}
