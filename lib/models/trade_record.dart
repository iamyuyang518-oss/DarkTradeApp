import 'package:hive/hive.dart';

part 'trade_record.g.dart';

@HiveType(typeId: 1)
class TradeRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String careerId;

  @HiveField(2)
  final String type; // 'buy' or 'sell'

  @HiveField(3)
  final String symbol;

  @HiveField(4)
  final String name;

  @HiveField(5)
  final String marketType; // 'crypto', 'usStock', 'aShare'

  @HiveField(6)
  final double quantity;

  @HiveField(7)
  final double price;

  @HiveField(8)
  final double? pnl; // null for buys, set for sells

  @HiveField(9)
  final DateTime createdAt;

  TradeRecord({
    required this.id,
    required this.careerId,
    required this.type,
    required this.symbol,
    required this.name,
    required this.marketType,
    required this.quantity,
    required this.price,
    this.pnl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
