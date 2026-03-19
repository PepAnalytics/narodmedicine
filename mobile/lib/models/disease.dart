import 'symptom.dart';

/// Заболевание
class Disease {
  final int id;
  final String name;
  final String description;
  final List<Symptom> symptoms;
  final double? matchScore;

  const Disease({
    required this.id,
    required this.name,
    required this.description,
    this.symptoms = const [],
    this.matchScore,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    final symptomsJson = json['symptoms'] as List<dynamic>?;
    return Disease(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      symptoms: symptomsJson != null
          ? symptomsJson.map((s) => Symptom.fromJson(s)).toList()
          : [],
      matchScore: (json['match_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'symptoms': symptoms.map((s) => s.toJson()).toList(),
      if (matchScore != null) 'match_score': matchScore,
    };
  }
}
