// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlockRuleAdapter extends TypeAdapter<BlockRule> {
  @override
  final int typeId = 3;

  @override
  BlockRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockRule(
      packageName: fields[0] as String,
      appName: fields[1] as String?,
      dailyLimitMinutes: fields[2] as int,
      isBlocked: fields[3] as bool,
      emergencyAllowed: fields[4] as bool,
      lastEmergencyDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BlockRule obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName)
      ..writeByte(2)
      ..write(obj.dailyLimitMinutes)
      ..writeByte(3)
      ..write(obj.isBlocked)
      ..writeByte(4)
      ..write(obj.emergencyAllowed)
      ..writeByte(5)
      ..write(obj.lastEmergencyDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyUsageAdapter extends TypeAdapter<DailyUsage> {
  @override
  final int typeId = 4;

  @override
  DailyUsage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyUsage(
      packageName: fields[0] as String,
      date: fields[1] as DateTime,
      usedMinutes: fields[2] as int,
      emergencyAllowedUntil: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.usedMinutes)
      ..writeByte(3)
      ..write(obj.emergencyAllowedUntil);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
