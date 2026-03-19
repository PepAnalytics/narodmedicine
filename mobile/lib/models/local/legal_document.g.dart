// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LegalDocumentAdapter extends TypeAdapter<LegalDocument> {
  @override
  final int typeId = 7;

  @override
  LegalDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegalDocument(
      type: fields[0] as String,
      version: fields[1] as String,
      content: fields[2] as String,
      effectiveFrom: fields[3] as DateTime,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LegalDocument obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.version)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.effectiveFrom)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
