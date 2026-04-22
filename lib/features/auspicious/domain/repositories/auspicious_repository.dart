import '../entities/auspicious_day_entity.dart';

abstract class AuspiciousRepository {
  Future<List<AuspiciousDayEntity>> getAuspiciousDays();
}
