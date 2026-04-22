class AuspiciousDayEntity {
  final String dateKey;

  final String titleEn;
  final String titleBo;

  final String? descriptionEn;
  final String? descriptionBo;

  final String? imageKey;

  final bool isMajor;

  const AuspiciousDayEntity({
    required this.dateKey,
    required this.titleEn,
    required this.titleBo,
    this.descriptionEn,
    this.descriptionBo,
    this.imageKey,
    this.isMajor = false,
  });
}