// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_remedy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalRemedyAdapter extends TypeAdapter<LocalRemedy> {
  @override
  final int typeId = 5;

  @override
  LocalRemedy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalRemedy(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      recipe: fields[3] as String,
      risks: fields[4] as String,
      source: fields[5] as String,
      evidenceLevelId: fields[6] as int,
      region: fields[7] as String,
      culturalContext: fields[8] as String?,
      likesCount: fields[9] as int,
      dislikesCount: fields[10] as int,
      diseaseId: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LocalRemedy obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.recipe)
      ..writeByte(4)
      ..write(obj.risks)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.evidenceLevelId)
      ..writeByte(7)
      ..write(obj.region)
      ..writeByte(8)
      ..write(obj.culturalContext)
      ..writeByte(9)
      ..write(obj.likesCount)
      ..writeByte(10)
      ..write(obj.dislikesCount)
      ..writeByte(11)
      ..write(obj.diseaseId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalRemedyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
