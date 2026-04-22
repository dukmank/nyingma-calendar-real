/// The authenticated user's profile.
///
/// [id] is the stable server-side identifier (UUID). When the app runs
/// in offline-only mode before any account is created, the id defaults to
/// the string 'local'.
class UserProfileEntity {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final DateTime joinedAt;
  final DateTime updatedAt;

  const UserProfileEntity({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.bio,
    required this.joinedAt,
    required this.updatedAt,
  });

  /// Default "guest" profile used before the user sets up their account.
  factory UserProfileEntity.guest() => UserProfileEntity(
        id: 'local',
        displayName: 'Dharma Practitioner',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  UserProfileEntity copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    DateTime? updatedAt,
  }) =>
      UserProfileEntity(
        id: id,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        joinedAt: joinedAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// First letter(s) of the display name, used as avatar initials fallback.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
