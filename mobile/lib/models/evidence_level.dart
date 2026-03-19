import 'dart:ui';

/// Уровень доказательности метода лечения
class EvidenceLevel {
  final int id;
  final String code;
  final String description;
  final String color; // HEX цвет от бэкенда
  final int rank;

  const EvidenceLevel({
    required this.id,
    required this.code,
    required this.description,
    required this.color,
    required this.rank,
  });

  factory EvidenceLevel.fromJson(Map<String, dynamic> json) {
    return EvidenceLevel(
      id: json['id'] as int,
      code: json['code'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
      rank: json['rank'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'color': color,
      'rank': rank,
    };
  }

  /// Получить цвет из HEX строки
  Color get colorValue {
    final hex = color.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    }
    return const Color(0xFF9E9E9E); // Серый по умолчанию
  }

  /// Получить название уровня на основе кода
  String get name {
    switch (code.toUpperCase()) {
      case 'A':
        return 'Высокий';
      case 'B':
        return 'Средний';
      case 'C':
        return 'Низкий';
      default:
        return description;
    }
  }
}
