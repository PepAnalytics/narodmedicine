/// Симптом заболевания
class Symptom {
  final int id;
  final String name;
  final double? weight;

  const Symptom({required this.id, required this.name, this.weight});

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as int,
      name: json['name'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, if (weight != null) 'weight': weight};
  }
}
