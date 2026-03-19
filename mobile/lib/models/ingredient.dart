/// Ингредиент для рецепта
class Ingredient {
  final int id;
  final String name;
  final String? amount;
  final Map<String, String>? alternativeNames;

  const Ingredient({
    required this.id,
    required this.name,
    this.amount,
    this.alternativeNames,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    Map<String, String>? altNames;
    final altNamesJson = json['alternative_names'];
    if (altNamesJson is Map) {
      altNames = altNamesJson.map(
        (key, value) => MapEntry(key as String, value as String),
      );
    }

    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: json['amount'] as String?,
      alternativeNames: altNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      if (alternativeNames != null) 'alternative_names': alternativeNames,
    };
  }
}
