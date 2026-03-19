/// Ингредиент для рецепта
class Ingredient {
  final int id;
  final String name;
  final String? amount;

  const Ingredient({required this.id, required this.name, this.amount});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: json['amount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'amount': amount};
  }
}
