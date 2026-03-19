import 'package:hive/hive.dart';

part 'local_disease.g.dart';

/// Локальная модель заболевания для кеширования в Hive
@HiveType(typeId: 1)
class LocalDisease {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  LocalDisease({
    required this.id,
    required this.name,
    required this.description,
  });

  factory LocalDisease.fromMap(Map<String, dynamic> map) {
    return LocalDisease(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }
}
