import 'package:dark_trade_app/services/market_data_service.dart';
import 'package:dark_trade_app/services/portfolio_service.dart';
import 'package:flutter/material.dart';

/// Result of a trade execution attempt — UI layer decides how to display it.
class TradeResult {
  const TradeResult({required this.success, required this.message});
  final bool success;
  final String message;
}

/// Core business logic for the trade form, extracted from the monolithic
/// TradePage. Holds all mutable state (side, selected quote, price/qty
/// controllers), exposes computed values, and delegates execution to
/// [PortfolioService].
class TradeFormController extends ChangeNotifier {
  TradeFormController() {
    priceCtrl.addListener(_onFieldChanged);
    qtyCtrl.addListener(_onFieldChanged);
  }

  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  bool _isBuy = true;
  String? _activeStockId;
  StockQuote? _selectedQuote;

  // ---- public getters -------------------------------------------------------

  bool get isBuy => _isBuy;
  StockQuote? get selectedQuote => _selectedQuote;

  double get price {
    final s = priceCtrl.text.replaceAll(',', '');
    return double.tryParse(s) ?? 0;
  }

  double get quantity {
    final s = qtyCtrl.text.replaceAll(',', '');
    return double.tryParse(s) ?? 0;
  }

  double? get estimatedCost {
    final p = price;
    final q = quantity;
    if (p > 0 && q > 0) return p * q;
    return null;
  }

  bool get canExecute {
    final p = price;
    final q = quantity;
    return p > 0 && q > 0 && _selectedQuote != null;
  }

  // ---- actions --------------------------------------------------------------

  void toggleSide(bool buy) {
    _isBuy = buy;
    notifyListeners();
  }

  void selectQuote(StockQuote quote) {
    _selectedQuote = quote;
    notifyListeners();
  }

  /// Auto-fill the price field from live market data when the selected symbol
  /// changes. [lookup] is a closure that avoids a direct BuildContext dependency.
  void autoFillPrice(
    StockQuote? Function(String stockId, MarketType type) lookup,
  ) {
    final quote = _selectedQuote;
    if (quote == null || quote.id == _activeStockId) return;
    _activeStockId = quote.id;
    final live = lookup(quote.id, quote.marketType);
    priceCtrl.text = (live?.price ?? quote.price).toStringAsFixed(2);
    notifyListeners();
  }

  /// Fills [fraction] of max affordable/available quantity into the qty field.
  void applyQuickPercent(double fraction, {required PortfolioService portfolio}) {
    final quote = _selectedQuote;
    if (quote == null) return;

    final p = price;
    if (p <= 0) return;

    double maxQty;
    if (_isBuy) {
      maxQty = portfolio.usdtBalance / p;
    } else {
      final holding = portfolio.getHolding(quote.id);
      maxQty = holding?.amount ?? 0;
    }

    final qty = maxQty * fraction;
    final s = qty >= 1 ? qty.toStringAsFixed(4) : qty.toStringAsFixed(6);
    qtyCtrl.text = s;
    notifyListeners();
  }

  /// Validates inputs and executes the trade via [portfolio].
  /// Returns a [TradeResult] so the UI layer can decide how to present feedback.
  TradeResult execute({required PortfolioService portfolio}) {
    final p = price;
    final q = quantity;

    if (p <= 0 || q <= 0) {
      return const TradeResult(success: false, message: '请输入有效的价格和数量');
    }

    final quote = _selectedQuote;
    if (quote == null) {
      return const TradeResult(success: false, message: '请先选择交易对');
    }

    // Validate balance / holdings (±1e-8 tolerance)
    if (_isBuy) {
      if (p * q > portfolio.usdtBalance + 1e-8) {
        return const TradeResult(success: false, message: 'USDT 余额不足');
      }
    } else {
      final holding = portfolio.getHolding(quote.id);
      if (holding == null || q > holding.amount + 1e-8) {
        return const TradeResult(success: false, message: '持仓不足');
      }
    }

    // Execute
    if (_isBuy) {
      portfolio.buy(
        stockId: quote.id,
        symbol: quote.symbol,
        name: quote.name,
        marketType: quote.marketType,
        amount: q,
        price: p,
      );
    } else {
      portfolio.sell(stockId: quote.id, amount: q, price: p);
    }

    qtyCtrl.clear();
    notifyListeners();

    final side = _isBuy ? '买入' : '卖出';
    return TradeResult(
      success: true,
      message: '$side ${quote.symbol} ${q.toStringAsFixed(4)}',
    );
  }

  @override
  void dispose() {
    priceCtrl.removeListener(_onFieldChanged);
    qtyCtrl.removeListener(_onFieldChanged);
    priceCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() => notifyListeners();
}
