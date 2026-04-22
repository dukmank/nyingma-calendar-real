import '../../domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.displayName,
    super.email,
    super.avatarUrl,
    super.bio,
    required super.joinedAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromEntity(UserProfileEntity e) => UserProfileModel(
        id: e.id,
        displayName: e.displayName,
        email: e.email,
        avatarUrl: e.avatarUrl,
        bio: e.bio,
        joinedAt: e.joinedAt,
        updatedAt: e.updatedAt,
      );

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String? ?? 'local',
        displayName: json['displayName'] as String? ?? 'Dharma Practitioner',
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        joinedAt: json['joinedAt'] != null
            ? DateTime.parse(json['joinedAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bio != null) 'bio': bio,
        'joinedAt': joinedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
