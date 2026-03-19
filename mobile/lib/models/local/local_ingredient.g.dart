// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_ingredient.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalIngredientAdapter extends TypeAdapter<LocalIngredient> {
  @override
  final int typeId = 6;

  @override
  LocalIngredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalIngredient(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String?,
      contraindications: fields[3] as String?,
      alternativeNames: (fields[4] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalIngredient obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.contraindications)
      ..writeByte(4)
      ..write(obj.alternativeNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalIngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
