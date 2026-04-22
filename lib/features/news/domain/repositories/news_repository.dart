import '../entities/news_post_entity.dart';

abstract class NewsRepository {
  Future<List<NewsPostEntity>> getPublishedNews({String? category});
  Future<NewsPostEntity?> getNewsById(String id);
}
