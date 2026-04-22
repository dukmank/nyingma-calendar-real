import '../../domain/entities/practice_entity.dart';

class PracticeModel extends PracticeEntity {
  const PracticeModel({
    required super.id,
    required super.title,
    super.description,
    super.colorHex,
    super.completionDates,
    super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PracticeModel.fromEntity(PracticeEntity e) => PracticeModel(
        id: e.id,
        title: e.title,
        description: e.description,
        colorHex: e.colorHex,
        completionDates: List.from(e.completionDates),
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  factory PracticeModel.fromJson(Map<String, dynamic> json) => PracticeModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        colorHex: json['colorHex'] as String? ?? '#8B1A1A',
        completionDates: (json['completionDates'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
        sortOrder: json['sortOrder'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'colorHex': colorHex,
        'completionDates': completionDates,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
