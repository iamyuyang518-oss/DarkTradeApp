import 'package:hive/hive.dart';

part 'trade_record.g.dart';

@HiveType(typeId: 2)
enum TradeType {
  @HiveField(0)
  buy,
  @HiveField(1)
  sell,
}

@HiveType(typeId: 3)
enum MarketType {
  @HiveField(0)
  crypto,
  @HiveField(1)
  usStock,
  @HiveField(2)
  aShare,
}

@HiveType(typeId: 1)
class TradeRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String careerId;

  @HiveField(2)
  final TradeType type;

  @HiveField(3)
  final String symbol;

  @HiveField(4)
  final String name;

  @HiveField(5)
  final MarketType marketType;

  @HiveField(6)
  final double quantity;

  @HiveField(7)
  final double price;

  @HiveField(8)
  final double? pnl;

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
  })  : assert(quantity > 0, 'quantity must be positive'),
        assert(price > 0, 'price must be positive'),
        createdAt = createdAt ?? DateTime.now();
}
