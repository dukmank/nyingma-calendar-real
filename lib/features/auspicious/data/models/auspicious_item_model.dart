import '../../domain/entities/auspicious_item_entity.dart';

class AuspiciousItemModel extends AuspiciousItemEntity {
  const AuspiciousItemModel({
    String? id,
    String? name,
  }) : super(id: id, name: name);

  factory AuspiciousItemModel.fromJson(Map<String, dynamic> json) {
    return AuspiciousItemModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
