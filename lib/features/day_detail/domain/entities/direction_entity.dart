class DirectionEntity {
  final String key;
  final String labelEn;
  final String labelBo;

  final String? direction; 

  const DirectionEntity({
    required this.key,
    required this.labelEn,
    required this.labelBo,
    this.direction,
  });
}