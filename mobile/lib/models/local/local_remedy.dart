import 'package:hive/hive.dart';

part 'local_remedy.g.dart';

/// Локальная модель метода лечения для кеширования в Hive
@HiveType(typeId: 5)
class LocalRemedy {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String recipe;

  @HiveField(4)
  final String risks;

  @HiveField(5)
  final String source;

  @HiveField(6)
  final int evidenceLevelId;

  @HiveField(7)
  final String region; // arab, persian, caucasian, turkic, chinese, indian, other

  @HiveField(8)
  final String? culturalContext;

  @HiveField(9)
  final int likesCount;

  @HiveField(10)
  final int dislikesCount;

  @HiveField(11)
  final int diseaseId;

  LocalRemedy({
    required this.id,
    required this.name,
    required this.description,
    required this.recipe,
    required this.risks,
    required this.source,
    required this.evidenceLevelId,
    required this.region,
    this.culturalContext,
    required this.likesCount,
    required this.dislikesCount,
    required this.diseaseId,
  });

  factory LocalRemedy.fromMap(Map<String, dynamic> map) {
    return LocalRemedy(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      recipe: map['recipe'] as String,
      risks: map['risks'] as String? ?? '',
      source: map['source'] as String? ?? '',
      evidenceLevelId: map['evidence_level_id'] as int,
      region: map['region'] as String? ?? 'other',
      culturalContext: map['cultural_context'] as String?,
      likesCount: map['likes_count'] as int? ?? 0,
      dislikesCount: map['dislikes_count'] as int? ?? 0,
      diseaseId: map['disease_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'recipe': recipe,
      'risks': risks,
      'source': source,
      'evidence_level_id': evidenceLevelId,
      'region': region,
      if (culturalContext != null) 'cultural_context': culturalContext,
      'likes_count': likesCount,
      'dislikes_count': dislikesCount,
      'disease_id': diseaseId,
    };
  }

  /// Получить отображаемое название региона
  String get regionName {
    switch (region.toLowerCase()) {
      case 'arab':
        return 'Арабский';
      case 'persian':
        return 'Персидский';
      case 'caucasian':
        return 'Кавказский';
      case 'turkic':
        return 'Тюркский';
      case 'chinese':
        return 'Китайский';
      case 'indian':
        return 'Индийский (Аюрведа)';
      case 'other':
      default:
        return 'Другой';
    }
  }

  /// Получить эмодзи флага для региона
  String get regionEmoji {
    switch (region.toLowerCase()) {
      case 'arab':
        return '🇸🇦';
      case 'persian':
        return '🇮🇷';
      case 'caucasian':
        return '🏔️';
      case 'turkic':
        return '🇹🇷';
      case 'chinese':
        return '🇨🇳';
      case 'indian':
        return '🇮🇳';
      case 'other':
      default:
        return '🌍';
    }
  }
}
