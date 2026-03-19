import 'package:hive/hive.dart';

part 'legal_document.g.dart';

/// Локальная модель юридического документа
@HiveType(typeId: 7)
class LegalDocument {
  @HiveField(0)
  final String type; // terms_of_service или privacy_policy

  @HiveField(1)
  final String version;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime effectiveFrom;

  @HiveField(4)
  final DateTime createdAt;

  LegalDocument({
    required this.type,
    required this.version,
    required this.content,
    required this.effectiveFrom,
    required this.createdAt,
  });

  factory LegalDocument.fromMap(Map<String, dynamic> map) {
    return LegalDocument(
      type: map['type'] as String,
      version: map['version'] as String,
      content: map['content'] as String,
      effectiveFrom: DateTime.parse(map['effective_from'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'version': version,
      'content': content,
      'effective_from': effectiveFrom.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
