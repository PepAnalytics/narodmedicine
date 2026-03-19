import 'package:hive/hive.dart';

part 'local_symptom.g.dart';

/// Локальная модель симптома для кеширования в Hive
@HiveType(typeId: 0)
class LocalSymptom {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  LocalSymptom({required this.id, required this.name});

  factory LocalSymptom.fromMap(Map<String, dynamic> map) {
    return LocalSymptom(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
