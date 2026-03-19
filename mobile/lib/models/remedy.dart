import 'evidence_level.dart';
import 'ingredient.dart';

/// Метод лечения (народный рецепт)
class Remedy {
  final int id;
  final int? diseaseId;
  final String name;
  final String description;
  final String recipe;
  final List<Ingredient> ingredients;
  final String risks;
  final String source;
  final EvidenceLevel evidenceLevel;
  final int likesCount;
  final int dislikesCount;
  final String region;
  final String? culturalContext;

  const Remedy({
    required this.id,
    this.diseaseId,
    required this.name,
    required this.description,
    required this.recipe,
    this.ingredients = const [],
    this.risks = '',
    this.source = '',
    required this.evidenceLevel,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.region = 'other',
    this.culturalContext,
  });

  factory Remedy.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'] as List<dynamic>?;
    return Remedy(
      id: json['id'] as int,
      diseaseId: json['disease_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
      recipe: json['recipe'] as String,
      ingredients: ingredientsJson != null
          ? ingredientsJson.map((i) => Ingredient.fromJson(i)).toList()
          : [],
      risks: json['risks'] as String? ?? '',
      source: json['source'] as String? ?? '',
      evidenceLevel: json['evidence_level'] != null
          ? EvidenceLevel.fromJson(json['evidence_level'])
          : EvidenceLevel(
              id: 0,
              code: 'UNKNOWN',
              description: 'Неизвестный',
              color: '#9E9E9E',
              rank: 0,
            ),
      likesCount: json['likes_count'] as int? ?? 0,
      dislikesCount: json['dislikes_count'] as int? ?? 0,
      region: json['region'] as String? ?? 'other',
      culturalContext: json['cultural_context'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (diseaseId != null) 'disease_id': diseaseId,
      'name': name,
      'description': description,
      'recipe': recipe,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'risks': risks,
      'source': source,
      'evidence_level': evidenceLevel.toJson(),
      'likes_count': likesCount,
      'dislikes_count': dislikesCount,
    };
  }
}

/// Краткая информация о методе лечения (для списка в болезни)
class RemedyBrief {
  final int id;
  final String name;
  final String shortDescription;
  final EvidenceLevel evidenceLevel;
  final int likesCount;
  final int dislikesCount;

  const RemedyBrief({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.evidenceLevel,
    this.likesCount = 0,
    this.dislikesCount = 0,
  });

  factory RemedyBrief.fromJson(Map<String, dynamic> json) {
    return RemedyBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      shortDescription: json['short_description'] as String,
      evidenceLevel: EvidenceLevel.fromJson(json['evidence_level']),
      likesCount: json['likes_count'] as int? ?? 0,
      dislikesCount: json['dislikes_count'] as int? ?? 0,
    );
  }
}
