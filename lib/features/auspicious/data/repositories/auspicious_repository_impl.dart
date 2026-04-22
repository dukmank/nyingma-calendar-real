import '../../domain/entities/auspicious_day_entity.dart';
import '../../domain/repositories/auspicious_repository.dart';

class AuspiciousRepositoryImpl implements AuspiciousRepository {
  @override
  Future<List<AuspiciousDayEntity>> getAuspiciousDays() async => const [];
}
