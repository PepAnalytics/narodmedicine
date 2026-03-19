// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_evidence_level.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalEvidenceLevelAdapter extends TypeAdapter<LocalEvidenceLevel> {
  @override
  final int typeId = 2;

  @override
  LocalEvidenceLevel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalEvidenceLevel(
      id: fields[0] as int,
      code: fields[1] as String,
      description: fields[2] as String,
      color: fields[3] as String,
      rank: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LocalEvidenceLevel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.rank);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalEvidenceLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
