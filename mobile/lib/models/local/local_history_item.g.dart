// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalHistoryItemAdapter extends TypeAdapter<LocalHistoryItem> {
  @override
  final int typeId = 4;

  @override
  LocalHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalHistoryItem(
      remedyId: fields[0] as int,
      name: fields[1] as String,
      diseaseId: fields[2] as int,
      diseaseName: fields[3] as String,
      viewedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocalHistoryItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.remedyId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.diseaseId)
      ..writeByte(3)
      ..write(obj.diseaseName)
      ..writeByte(4)
      ..write(obj.viewedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
