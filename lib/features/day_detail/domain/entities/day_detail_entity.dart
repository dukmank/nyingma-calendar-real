import 'gregorian_info.dart';
import 'tibetan_info.dart';
import 'astrology_status_entity.dart';
import 'direction_entity.dart';

class DayDetailEntity {
  final String dateKey;

  final GregorianInfo gregorian;
  final TibetanInfo tibetan;

  final String? title;
  final String? titleBo;
  final String? imageKey;

  final String? significanceEn;
  final String? significanceBo;

  final String? wisdomEn;
  final String? wisdomBo;

  final String? elementCombination;
  final String? elementCombinationBo;
  final String? elementCombinationDescBo;

  final List<AstrologyStatusEntity> astrology;
  final List<DirectionEntity> directions;

  final List<String> eventIds;

  const DayDetailEntity({
    required this.dateKey,
    required this.gregorian,
    required this.tibetan,
    this.title,
    this.titleBo,
    this.imageKey,
    this.significanceEn,
    this.significanceBo,
    this.wisdomEn,
    this.wisdomBo,
    this.elementCombination,
    this.elementCombinationBo,
    this.elementCombinationDescBo,
    this.astrology = const [],
    this.directions = const [],
    this.eventIds = const [],
  });
}