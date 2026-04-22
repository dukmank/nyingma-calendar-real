/// Domain entity for a News Post fetched from Supabase.
class NewsEntity {
  final String id;
  final String titleEn;
  final String titleBo;
  final String excerptEn;
  final String excerptBo;
  final String contentEn;
  final String contentBo;

  /// One of: 'teachings' | 'lineage' | 'announcements' | 'community'
  final String category;

  /// Full public URL (Backblaze B2 or any CDN)
  final String? imageUrl;

  final String author;
  final DateTime publishedAt;

  const NewsEntity({
    required this.id,
    required this.titleEn,
    required this.titleBo,
    required this.excerptEn,
    required this.excerptBo,
    required this.contentEn,
    required this.contentBo,
    required this.category,
    this.imageUrl,
    required this.author,
    required this.publishedAt,
  });
}
