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
      type: fields[2] as TradeType,
      symbol: fields[3] as String,
      name: fields[4] as String,
      marketType: fields[5] as MarketType,
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

class TradeTypeAdapter extends TypeAdapter<TradeType> {
  @override
  final int typeId = 2;

  @override
  TradeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TradeType.buy;
      case 1:
        return TradeType.sell;
      default:
        return TradeType.buy;
    }
  }

  @override
  void write(BinaryWriter writer, TradeType obj) {
    switch (obj) {
      case TradeType.buy:
        writer.writeByte(0);
        break;
      case TradeType.sell:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MarketTypeAdapter extends TypeAdapter<MarketType> {
  @override
  final int typeId = 3;

  @override
  MarketType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MarketType.crypto;
      case 1:
        return MarketType.usStock;
      case 2:
        return MarketType.aShare;
      default:
        return MarketType.crypto;
    }
  }

  @override
  void write(BinaryWriter writer, MarketType obj) {
    switch (obj) {
      case MarketType.crypto:
        writer.writeByte(0);
        break;
      case MarketType.usStock:
        writer.writeByte(1);
        break;
      case MarketType.aShare:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
