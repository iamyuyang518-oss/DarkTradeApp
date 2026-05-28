import 'package:hive/hive.dart';

part 'career.g.dart';

@HiveType(typeId: 0)
class Career extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final double initialBalance;

  @HiveField(3)
  double currentBalance;

  @HiveField(4)
  double totalPnl;

  @HiveField(5)
  int totalTrades;

  @HiveField(6)
  int winningTrades;

  @HiveField(7)
  double? bestTradePnl;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  List<double> equityHistory;

  Career({
    required this.id,
    required this.name,
    required this.initialBalance,
    this.currentBalance = 0,
    this.totalPnl = 0,
    this.totalTrades = 0,
    this.winningTrades = 0,
    this.bestTradePnl,
    DateTime? createdAt,
    List<double>? equityHistory,
  })  : createdAt = createdAt ?? DateTime.now(),
        equityHistory = equityHistory ?? [] {
    if (currentBalance == 0) {
      currentBalance = initialBalance;
    }
  }

  double get totalReturnRate =>
      initialBalance > 0 ? (totalPnl / initialBalance) * 100 : 0;

  double get winRate =>
      totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0;

  void recordTrade(double pnl) {
    totalTrades++;
    if (pnl > 0) winningTrades++;
    totalPnl += pnl;
    currentBalance += pnl;
    if (bestTradePnl == null || pnl > bestTradePnl!) bestTradePnl = pnl;
  }

  void recordEquitySnapshot(double totalAssetValue) {
    equityHistory.add(totalAssetValue);
    if (equityHistory.length > 90) {
      equityHistory.removeAt(0);
    }
  }
}
