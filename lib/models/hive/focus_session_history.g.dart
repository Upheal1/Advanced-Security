// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusSessionHistoryAdapter extends TypeAdapter<FocusSessionHistory> {
  @override
  final int typeId = 2;

  @override
  FocusSessionHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusSessionHistory(
      id: fields[0] as String,
      type: fields[1] as FocusSessionType,
      durationSeconds: fields[2] as int,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      completed: fields[5] as bool,
      blockedApps: (fields[6] as List).cast<String>(),
      sessionNumber: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSessionHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.blockedApps)
      ..writeByte(7)
      ..write(obj.sessionNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FocusSessionTypeAdapter extends TypeAdapter<FocusSessionType> {
  @override
  final int typeId = 1;

  @override
  FocusSessionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FocusSessionType.focus;
      case 1:
        return FocusSessionType.shortBreak;
      case 2:
        return FocusSessionType.longBreak;
      default:
        return FocusSessionType.focus;
    }
  }

  @override
  void write(BinaryWriter writer, FocusSessionType obj) {
    switch (obj) {
      case FocusSessionType.focus:
        writer.writeByte(0);
        break;
      case FocusSessionType.shortBreak:
        writer.writeByte(1);
        break;
      case FocusSessionType.longBreak:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
