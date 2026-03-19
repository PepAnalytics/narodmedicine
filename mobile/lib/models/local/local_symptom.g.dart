// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_symptom.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalSymptomAdapter extends TypeAdapter<LocalSymptom> {
  @override
  final int typeId = 0;

  @override
  LocalSymptom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSymptom(id: fields[0] as int, name: fields[1] as String);
  }

  @override
  void write(BinaryWriter writer, LocalSymptom obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSymptomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
