import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';

/// Thin SharedPreferences cache so the news list survives offline.
class NewsLocalCache {
  static const _kNewsList = 'nmc_news_list';
  static const _kNewsTs   = 'nmc_news_ts';

  /// How long cached data is considered fresh (1 hour).
  static const _ttl = Duration(hours: 1);

  final SharedPreferences _prefs;
  NewsLocalCache(this._prefs);

  bool get isFresh {
    final raw = _prefs.getString(_kNewsTs);
    if (raw == null) return false;
    final ts = DateTime.tryParse(raw);
    if (ts == null) return false;
    return DateTime.now().difference(ts) < _ttl;
  }

  List<NewsModel>? read() {
    final raw = _prefs.getString(_kNewsList);
    if (raw == null) return null;
    try {
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(NewsModel.fromJson).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(List<NewsModel> items) async {
    final encoded = json.encode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_kNewsList, encoded);
    await _prefs.setString(_kNewsTs, DateTime.now().toIso8601String());
  }

  Future<void> clear() async {
    await _prefs.remove(_kNewsList);
    await _prefs.remove(_kNewsTs);
  }
}
