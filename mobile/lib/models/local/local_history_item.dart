import 'package:hive/hive.dart';

part 'local_history_item.g.dart';

/// Локальная модель истории просмотров для кеширования в Hive
@HiveType(typeId: 4)
class LocalHistoryItem {
  @HiveField(0)
  final int remedyId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int diseaseId;

  @HiveField(3)
  final String diseaseName;

  @HiveField(4)
  final DateTime viewedAt;

  LocalHistoryItem({
    required this.remedyId,
    required this.name,
    required this.diseaseId,
    required this.diseaseName,
    required this.viewedAt,
  });

  factory LocalHistoryItem.fromMap(Map<String, dynamic> map) {
    return LocalHistoryItem(
      remedyId: map['remedy_id'] as int,
      name: map['name'] as String,
      diseaseId: map['disease_id'] as int,
      diseaseName: map['disease_name'] as String,
      viewedAt: map['viewed_at'] as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'remedy_id': remedyId,
      'name': name,
      'disease_id': diseaseId,
      'disease_name': diseaseName,
      'viewed_at': viewedAt,
    };
  }
}
