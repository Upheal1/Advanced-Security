// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_usage_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppUsageCacheAdapter extends TypeAdapter<AppUsageCache> {
  @override
  final int typeId = 0;

  @override
  AppUsageCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppUsageCache(
      appName: fields[0] as String,
      packageName: fields[1] as String,
      totalTimeMs: fields[2] as int,
      date: fields[3] as DateTime,
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppUsageCache obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.totalTimeMs)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
