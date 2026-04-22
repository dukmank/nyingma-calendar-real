enum AstrologyStatusType {
  auspicious,
  inauspicious,
  caution,
  neutral,
}

class AstrologyStatusEntity {
  final String key; 
  final String labelEn;
  final String labelBo;

  final AstrologyStatusType status;

  final String? iconKey;

  const AstrologyStatusEntity({
    required this.key,
    required this.labelEn,
    required this.labelBo,
    required this.status,
    this.iconKey,
  });
}