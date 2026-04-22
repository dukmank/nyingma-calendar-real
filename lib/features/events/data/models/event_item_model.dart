import '../../domain/entities/event_entity.dart';

/// Parses one entry from `data/events/events.json → events[]`.
///
/// Actual JSON structure:
/// {
///   "id": "evt_20260218_1",
///   "date_key": "2026-02-18",
///   "name_en": "Tibetan New Year (Losar)",
///   "name_bo": "...",
///   "category_en": "Annual Festival",
///   "category_bo": "...",
///   "details_en": "...",
///   "details_bo": "...",
///   "image_key": "losar"
/// }
class EventItemModel extends EventEntity {
  const EventItemModel({
    required super.id,
    required super.titleEn,
    required super.titleBo,
    super.descriptionEn,
    super.descriptionBo,
    super.imageKey,
    required super.dateKey,
    super.lunarDate,
    super.category,
  });

  factory EventItemModel.fromJson(Map<String, dynamic> json) => EventItemModel(
        id:            json['id'] as String? ?? '',
        titleEn:       json['name_en'] as String? ?? '',
        titleBo:       json['name_bo'] as String? ?? '',
        descriptionEn: json['details_en'] as String?,
        descriptionBo: json['details_bo'] as String?,
        imageKey:      (json['image_key'] ?? json['image']) as String?,
        dateKey:       (json['date_key'] ?? json['date']) as String? ?? '',
        lunarDate:     null,  // not in events.json
        category:      json['category_en'] as String?,
      );
}
