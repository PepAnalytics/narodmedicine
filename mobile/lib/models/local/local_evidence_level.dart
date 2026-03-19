import 'package:hive/hive.dart';
import 'dart:ui';

part 'local_evidence_level.g.dart';

/// Локальная модель уровня доказательности для кеширования в Hive
@HiveType(typeId: 2)
class LocalEvidenceLevel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String color; // HEX строка

  @HiveField(4)
  final int rank;

  LocalEvidenceLevel({
    required this.id,
    required this.code,
    required this.description,
    required this.color,
    required this.rank,
  });

  factory LocalEvidenceLevel.fromMap(Map<String, dynamic> map) {
    return LocalEvidenceLevel(
      id: map['id'] as int,
      code: map['code'] as String,
      description: map['description'] as String,
      color: map['color'] as String,
      rank: map['rank'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'color': color,
      'rank': rank,
    };
  }

  Color get colorValue {
    final hex = color.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    }
    return const Color(0xFF9E9E9E);
  }

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
