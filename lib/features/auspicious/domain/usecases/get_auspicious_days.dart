import '../entities/auspicious_day_entity.dart';
import '../repositories/auspicious_repository.dart';

class GetAuspiciousDays {
  final AuspiciousRepository _repository;

  GetAuspiciousDays(this._repository);

  Future<List<AuspiciousDayEntity>> call() => _repository.getAuspiciousDays();
}
