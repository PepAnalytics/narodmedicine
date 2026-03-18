/// Уровень доказательности метода лечения
class EvidenceLevel {
  final String code;
  final String name;
  final int colorValue;

  const EvidenceLevel({
    required this.code,
    required this.name,
    required this.colorValue,
  });

  factory EvidenceLevel.fromJson(Map<String, dynamic> json) {
    return EvidenceLevel(
      code: json['code'] as String,
      name: json['name'] as String,
      colorValue: json['color'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name, 'color': colorValue};
  }

  /// Предустановленные уровни доказательности
  static const high = EvidenceLevel(
    code: 'HIGH',
    name: 'Высокий',
    colorValue: 0xFF4CAF50, // Зеленый
  );

  static const medium = EvidenceLevel(
    code: 'MEDIUM',
    name: 'Средний',
    colorValue: 0xFFFFC107, // Желтый
  );

  static const low = EvidenceLevel(
    code: 'LOW',
    name: 'Низкий',
    colorValue: 0xFFF44336, // Красный
  );

  static const unknown = EvidenceLevel(
    code: 'UNKNOWN',
    name: 'Неизвестный',
    colorValue: 0xFF9E9E9E, // Серый
  );
}
