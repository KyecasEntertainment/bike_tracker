// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RideSessionAdapter extends TypeAdapter<RideSession> {
  @override
  final int typeId = 0;

  @override
  RideSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RideSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      points: (fields[3] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(),
      isCompleted: fields[4] as bool,
      totalDistance: fields[5] as double,
      totalDuration: fields[6] as int,
      name: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RideSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.totalDistance)
      ..writeByte(6)
      ..write(obj.totalDuration)
      ..writeByte(7)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
