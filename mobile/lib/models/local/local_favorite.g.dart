// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_favorite.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalFavoriteAdapter extends TypeAdapter<LocalFavorite> {
  @override
  final int typeId = 3;

  @override
  LocalFavorite read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalFavorite(
      remedyId: fields[0] as int,
      name: fields[1] as String,
      diseaseId: fields[2] as int,
      diseaseName: fields[3] as String,
      evidenceLevelCode: fields[4] as String,
      addedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocalFavorite obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.remedyId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.diseaseId)
      ..writeByte(3)
      ..write(obj.diseaseName)
      ..writeByte(4)
      ..write(obj.evidenceLevelCode)
      ..writeByte(5)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFavoriteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
