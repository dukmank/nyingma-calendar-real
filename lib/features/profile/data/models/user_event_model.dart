import '../../domain/entities/user_event_entity.dart';

class UserEventModel extends UserEventEntity {
  const UserEventModel({
    required super.id,
    required super.title,
    super.content,
    required super.dateKey,
    super.timeOfDay,
    super.lunarDay,
    super.lunarLabel,
    super.imageKey,
    super.repeatType,
    super.reminderMinutes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserEventModel.fromEntity(UserEventEntity e) => UserEventModel(
        id: e.id,
        title: e.title,
        content: e.content,
        dateKey: e.dateKey,
        timeOfDay: e.timeOfDay,
        lunarDay: e.lunarDay,
        lunarLabel: e.lunarLabel,
        imageKey: e.imageKey,
        repeatType: e.repeatType,
        reminderMinutes: e.reminderMinutes,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  factory UserEventModel.fromJson(Map<String, dynamic> json) => UserEventModel(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        dateKey: json['dateKey'] as String,
        timeOfDay: json['timeOfDay'] as String? ?? '09:00',
        lunarDay: json['lunarDay'] as int? ?? 0,
        lunarLabel: json['lunarLabel'] as String? ?? '',
        imageKey: json['imageKey'] as String?,
        repeatType: json['repeatType'] as String? ?? 'never',
        reminderMinutes: json['reminderMinutes'] as int? ?? 0,
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
        'content': content,
        'dateKey': dateKey,
        'timeOfDay': timeOfDay,
        'lunarDay': lunarDay,
        'lunarLabel': lunarLabel,
        if (imageKey != null) 'imageKey': imageKey,
        'repeatType': repeatType,
        'reminderMinutes': reminderMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
