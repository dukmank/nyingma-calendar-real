class NewsPostEntity {
  final String id;
  final String titleEn;
  final String titleBo;
  final String excerptEn;
  final String excerptBo;
  final String contentEn;
  final String contentBo;
  final String category;  // 'teachings' | 'lineage' | 'announcements'
  final String imageUrl;
  final String author;
  final DateTime? publishedAt;
  final String status;
  final DateTime createdAt;

  const NewsPostEntity({
    required this.id,
    required this.titleEn,
    required this.titleBo,
    required this.excerptEn,
    required this.excerptBo,
    required this.contentEn,
    required this.contentBo,
    required this.category,
    required this.imageUrl,
    required this.author,
    this.publishedAt,
    required this.status,
    required this.createdAt,
  });

  String title(bool bo) => bo && titleBo.isNotEmpty ? titleBo : titleEn;
  String excerpt(bool bo) => bo && excerptBo.isNotEmpty ? excerptBo : excerptEn;
  String content(bool bo) => bo && contentBo.isNotEmpty ? contentBo : contentEn;
}
