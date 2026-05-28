// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeRecordAdapter extends TypeAdapter<TradeRecord> {
  @override
  final int typeId = 1;

  @override
  TradeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradeRecord(
      id: fields[0] as String,
      careerId: fields[1] as String,
      type: fields[2] as String,
      symbol: fields[3] as String,
      name: fields[4] as String,
      marketType: fields[5] as String,
      quantity: fields[6] as double,
      price: fields[7] as double,
      pnl: fields[8] as double?,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TradeRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.careerId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.symbol)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.marketType)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.price)
      ..writeByte(8)
      ..write(obj.pnl)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
