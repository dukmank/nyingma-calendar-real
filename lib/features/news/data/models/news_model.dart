import '../../domain/entities/news_entity.dart';

class NewsModel extends NewsEntity {
  const NewsModel({
    required super.id,
    required super.titleEn,
    required super.titleBo,
    required super.excerptEn,
    required super.excerptBo,
    required super.contentEn,
    required super.contentBo,
    required super.category,
    super.imageUrl,
    required super.author,
    required super.publishedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id:          json['id']?.toString() ?? '',
      titleEn:     json['title_en'] ?? '',
      titleBo:     json['title_bo'] ?? '',
      excerptEn:   json['excerpt_en'] ?? '',
      excerptBo:   json['excerpt_bo'] ?? '',
      contentEn:   json['content_en'] ?? '',
      contentBo:   json['content_bo'] ?? '',
      category:    json['category'] ?? 'teachings',
      imageUrl:    json['image_url'] as String?,
      author:      json['author'] ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'title_en':     titleEn,
    'title_bo':     titleBo,
    'excerpt_en':   excerptEn,
    'excerpt_bo':   excerptBo,
    'content_en':   contentEn,
    'content_bo':   contentBo,
    'category':     category,
    'image_url':    imageUrl,
    'author':       author,
    'published_at': publishedAt.toIso8601String(),
  };
}
