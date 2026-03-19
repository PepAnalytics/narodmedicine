import 'package:hive/hive.dart';

part 'local_ingredient.g.dart';

/// Локальная модель ингредиента для кеширования в Hive
@HiveType(typeId: 6)
class LocalIngredient {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? contraindications;

  @HiveField(4)
  final Map<String, String>? alternativeNames; // {lang: name}

  LocalIngredient({
    required this.id,
    required this.name,
    this.description,
    this.contraindications,
    this.alternativeNames,
  });

  factory LocalIngredient.fromMap(Map<String, dynamic> map) {
    Map<String, String>? altNames;
    final altNamesJson = map['alternative_names'];
    if (altNamesJson is Map) {
      altNames = altNamesJson.map(
        (key, value) => MapEntry(key as String, value as String),
      );
    }

    return LocalIngredient(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      contraindications: map['contraindications'] as String?,
      alternativeNames: altNames,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (contraindications != null) 'contraindications': contraindications,
      if (alternativeNames != null) 'alternative_names': alternativeNames,
    };
  }
}
