import '../../domain/entities/news_post_entity.dart';

class NewsPostModel extends NewsPostEntity {
  const NewsPostModel({
    required super.id,
    required super.titleEn,
    required super.titleBo,
    required super.excerptEn,
    required super.excerptBo,
    required super.contentEn,
    required super.contentBo,
    required super.category,
    required super.imageUrl,
    required super.author,
    super.publishedAt,
    required super.status,
    required super.createdAt,
  });

  factory NewsPostModel.fromJson(Map<String, dynamic> json) {
    return NewsPostModel(
      id:         json['id'] as String,
      titleEn:    json['title_en'] as String? ?? '',
      titleBo:    json['title_bo'] as String? ?? '',
      excerptEn:  json['excerpt_en'] as String? ?? '',
      excerptBo:  json['excerpt_bo'] as String? ?? '',
      contentEn:  json['content_en'] as String? ?? '',
      contentBo:  json['content_bo'] as String? ?? '',
      category:   json['category'] as String? ?? 'announcements',
      imageUrl:   json['image_url'] as String? ?? '',
      author:     json['author'] as String? ?? 'Vajra Lotus Foundation',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      status:     json['status'] as String? ?? 'published',
      createdAt:  DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
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
    'published_at': publishedAt?.toIso8601String(),
    'status':       status,
    'created_at':   createdAt.toIso8601String(),
  };
}
