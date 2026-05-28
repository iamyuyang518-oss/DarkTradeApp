// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'career.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CareerAdapter extends TypeAdapter<Career> {
  @override
  final int typeId = 0;

  @override
  Career read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Career(
      id: fields[0] as String,
      name: fields[1] as String,
      initialBalance: fields[2] as double,
      currentBalance: fields[3] as double,
      totalPnl: fields[4] as double,
      totalTrades: fields[5] as int,
      winningTrades: fields[6] as int,
      bestTradePnl: fields[7] as double,
      createdAt: fields[8] as DateTime?,
      equityHistory: (fields[9] as List?)?.cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, Career obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.initialBalance)
      ..writeByte(3)
      ..write(obj.currentBalance)
      ..writeByte(4)
      ..write(obj.totalPnl)
      ..writeByte(5)
      ..write(obj.totalTrades)
      ..writeByte(6)
      ..write(obj.winningTrades)
      ..writeByte(7)
      ..write(obj.bestTradePnl)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.equityHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
