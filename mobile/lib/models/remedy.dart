import 'evidence_level.dart';
import 'ingredient.dart';

/// Метод лечения (народный рецепт)
class Remedy {
  final int id;
  final String name;
  final String description;
  final String recipe;
  final List<Ingredient> ingredients;
  final String risks;
  final EvidenceLevel evidenceLevel;
  final String source;

  const Remedy({
    required this.id,
    required this.name,
    required this.description,
    required this.recipe,
    this.ingredients = const [],
    this.risks = '',
    required this.evidenceLevel,
    required this.source,
  });

  factory Remedy.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['ingredients'] as List<dynamic>?;
    return Remedy(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      recipe: json['recipe'] as String,
      ingredients: ingredientsJson != null
          ? ingredientsJson.map((i) => Ingredient.fromJson(i)).toList()
          : [],
      risks: json['risks'] as String? ?? '',
      evidenceLevel: json['evidenceLevel'] != null
          ? EvidenceLevel.fromJson(json['evidenceLevel'])
          : EvidenceLevel.unknown,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'recipe': recipe,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'risks': risks,
      'evidenceLevel': evidenceLevel.toJson(),
      'source': source,
    };
  }
}
