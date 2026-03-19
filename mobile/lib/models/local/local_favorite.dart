import 'package:hive/hive.dart';

part 'local_favorite.g.dart';

/// Локальная модель избранного метода для кеширования в Hive
@HiveType(typeId: 3)
class LocalFavorite {
  @HiveField(0)
  final int remedyId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int diseaseId;

  @HiveField(3)
  final String diseaseName;

  @HiveField(4)
  final String evidenceLevelCode;

  @HiveField(5)
  final DateTime addedAt;

  LocalFavorite({
    required this.remedyId,
    required this.name,
    required this.diseaseId,
    required this.diseaseName,
    required this.evidenceLevelCode,
    required this.addedAt,
  });

  factory LocalFavorite.fromMap(Map<String, dynamic> map) {
    return LocalFavorite(
      remedyId: map['remedy_id'] as int,
      name: map['name'] as String,
      diseaseId: map['disease_id'] as int,
      diseaseName: map['disease_name'] as String,
      evidenceLevelCode: map['evidence_level_code'] as String,
      addedAt: map['added_at'] as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'remedy_id': remedyId,
      'name': name,
      'disease_id': diseaseId,
      'disease_name': diseaseName,
      'evidence_level_code': evidenceLevelCode,
      'added_at': addedAt,
    };
  }
}
