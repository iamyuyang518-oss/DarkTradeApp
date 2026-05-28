import 'package:flutter/foundation.dart';

import 'market_data_service.dart';

/// 单笔持仓记录。
@immutable
class Holding {
  const Holding({
    required this.stockId,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.avgCost,
    required this.lastKnownPrice,
    required this.marketType,
  });

  final String stockId;
  final String symbol;
  final String name;
  final double amount;
  final double avgCost;
  final double lastKnownPrice;
  final MarketType marketType;

  double get costBasis => amount * avgCost;
  double get valueUsd => amount * lastKnownPrice;
  double get unrealizedPnl => valueUsd - costBasis;

  Holding copyWith({
    double? amount,
    double? avgCost,
    double? lastKnownPrice,
  }) {
    return Holding(
      stockId: stockId,
      symbol: symbol,
      name: name,
      amount: amount ?? this.amount,
      avgCost: avgCost ?? this.avgCost,
      lastKnownPrice: lastKnownPrice ?? this.lastKnownPrice,
      marketType: marketType,
    );
  }
}

/// 模拟持仓账本：管理 USDT 余额、持仓列表、买入/卖出逻辑。
class PortfolioService extends ChangeNotifier {
  final List<Holding> _holdings = [];
  double _usdtBalance = 0;

  List<Holding> get holdings => List.unmodifiable(_holdings);
  double get usdtBalance => _usdtBalance;

  double get totalValueUsd {
    var total = _usdtBalance;
    for (final h in _holdings) {
      total += h.valueUsd;
    }
    return total;
  }

  Holding? getHolding(String stockId) {
    try {
      return _holdings.firstWhere((h) => h.stockId == stockId);
    } catch (_) {
      return null;
    }
  }

  int _holdingIndex(String stockId) => _holdings.indexWhere((h) => h.stockId == stockId);

  // ---- demo seed ----------------------------------------------------------

  void seedDemo() {
    _usdtBalance = 12500;

    _holdings.addAll([
      const Holding(
        stockId: 'BTCUSDT',
        symbol: 'BTC',
        name: 'Bitcoin',
        amount: 0.42,
        avgCost: 212462.19,
        lastKnownPrice: 212462.19,
        marketType: MarketType.crypto,
      ),
      const Holding(
        stockId: 'ETHUSDT',
        symbol: 'ETH',
        name: 'Ethereum',
        amount: 5.2,
        avgCost: 3500.03,
        lastKnownPrice: 3500.03,
        marketType: MarketType.crypto,
      ),
    ]);

    notifyListeners();
  }

  // ---- trading ------------------------------------------------------------

  /// 买入：减少 USDT 余额，增加/更新持仓。
  void buy({
    required String stockId,
    required String symbol,
    required String name,
    required MarketType marketType,
    required double amount,
    required double price,
  }) {
    final cost = amount * price;
    if (cost > _usdtBalance + 1e-8) return;

    _usdtBalance -= cost;

    final idx = _holdingIndex(stockId);
    if (idx >= 0) {
      final old = _holdings[idx];
      final totalAmount = old.amount + amount;
      final newAvgCost = (old.costBasis + cost) / totalAmount;
      _holdings[idx] = old.copyWith(
        amount: totalAmount,
        avgCost: newAvgCost,
        lastKnownPrice: price,
      );
    } else {
      _holdings.add(Holding(
        stockId: stockId,
        symbol: symbol,
        name: name,
        amount: amount,
        avgCost: price,
        lastKnownPrice: price,
        marketType: marketType,
      ));
    }

    notifyListeners();
  }

  /// 卖出：增加 USDT 余额，减少/移除持仓。
  void sell({
    required String stockId,
    required double amount,
    required double price,
  }) {
    final idx = _holdingIndex(stockId);
    if (idx < 0) return;
    final old = _holdings[idx];
    if (amount > old.amount + 1e-8) return;

    _usdtBalance += amount * price;

    final remaining = old.amount - amount;
    if (remaining <= 1e-8) {
      _holdings.removeAt(idx);
    } else {
      _holdings[idx] = old.copyWith(amount: remaining, lastKnownPrice: price);
    }

    notifyListeners();
  }

  /// 批量更新行情价格（资产页被动调用）。
  void updatePrices(Map<String, double> stockIdToPrice) {
    var changed = false;
    for (var i = 0; i < _holdings.length; i++) {
      final p = stockIdToPrice[_holdings[i].stockId];
      if (p != null && (p - _holdings[i].lastKnownPrice).abs() > 1e-8) {
        _holdings[i] = _holdings[i].copyWith(lastKnownPrice: p);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
