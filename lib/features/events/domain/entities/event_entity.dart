/// Domain entity for a Nyingmapa calendar event (Losar, Düchen, etc.).
class EventEntity {
  final String id;

  /// English title, e.g. "Losar – Tibetan New Year"
  final String titleEn;

  /// Tibetan title
  final String titleBo;

  /// Optional long description (English)
  final String? descriptionEn;

  /// Optional long description (Tibetan)
  final String? descriptionBo;

  /// Optional image asset key (without extension), e.g. "losar_celebration"
  final String? imageKey;

  /// Gregorian date key: "YYYY-MM-DD"
  final String dateKey;

  /// Tibetan lunar date label, e.g. "Month 1, Day 1"
  final String? lunarDate;

  /// Category tag (English), e.g. "Annual Festival", "Birthday"
  final String? category;

  /// Category tag (Tibetan)
  final String? categoryBo;

  const EventEntity({
    required this.id,
    required this.titleEn,
    required this.titleBo,
    this.descriptionEn,
    this.descriptionBo,
    this.imageKey,
    required this.dateKey,
    this.lunarDate,
    this.category,
    this.categoryBo,
  });
}
