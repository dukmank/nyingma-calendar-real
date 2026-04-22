import '../../domain/entities/event_entity.dart';

/// Full event model used when reading / writing user-created events locally.
/// Also used when parsing from `events_index.json`.
class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.titleEn,
    required super.titleBo,
    super.descriptionEn,
    super.descriptionBo,
    super.imageKey,
    required super.dateKey,
    super.lunarDate,
    super.category,
    super.categoryBo,
  });

  /// Parse one entry from `data/events/events.json → events[]`.
  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id:            json['id'] as String? ?? '',
        titleEn:       json['name_en'] as String? ?? '',
        titleBo:       json['name_bo'] as String? ?? '',
        descriptionEn: json['details_en'] as String?,
        descriptionBo: json['details_bo'] as String?,
        imageKey:      (json['image_key'] ?? json['image']) as String?,
        dateKey:       (json['date_key'] ?? json['date']) as String? ?? '',
        lunarDate:     null,  // not present in events.json
        category:      json['category_en'] as String?,
        categoryBo:    json['category_bo'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id':       id,
        'name_en':  titleEn,
        'name_bo':  titleBo,
        if (descriptionEn != null) 'details_en': descriptionEn,
        if (descriptionBo != null) 'details_bo': descriptionBo,
        if (imageKey != null) 'image_key': imageKey,
        'date_key': dateKey,
        if (category != null) 'category_en': category,
        if (categoryBo != null) 'category_bo': categoryBo,
      };
}
