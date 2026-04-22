import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/news_post_entity.dart';
import '../../data/repositories/news_repository_impl.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final newsRepositoryProvider = Provider((_) => NewsRepositoryImpl());

/// All published news (for "Latest" tab)
final newsListProvider = FutureProvider<List<NewsPostEntity>>((ref) {
  return ref.watch(newsRepositoryProvider).getPublishedNews();
});

/// Category-filtered news
final newsByCategoryProvider =
    FutureProvider.family<List<NewsPostEntity>, String>((ref, category) {
  return ref.watch(newsRepositoryProvider).getPublishedNews(category: category);
});

/// Single post detail
final newsDetailProvider =
    FutureProvider.family<NewsPostEntity?, String>((ref, id) {
  return ref.watch(newsRepositoryProvider).getNewsById(id);
});
