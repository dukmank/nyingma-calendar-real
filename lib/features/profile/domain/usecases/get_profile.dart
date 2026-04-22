import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;
  GetProfile(this.repository);

  Future<UserProfileEntity> call() => repository.getProfile();
}
