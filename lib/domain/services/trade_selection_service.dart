import 'package:flutter/foundation.dart';

import 'market_data_service.dart';

/// 跨 Tab 桥梁：行情页点击 → 交易页自动填入交易对。
class TradeSelectionService extends ChangeNotifier {
  StockQuote? _selectedQuote;
  bool _shouldNavigateToTrade = false;

  StockQuote? get selectedQuote => _selectedQuote;
  bool get shouldNavigateToTrade => _shouldNavigateToTrade;

  void selectForTrade(StockQuote quote) {
    _selectedQuote = quote;
    _shouldNavigateToTrade = true;
    notifyListeners();
  }

  void clearNavigation() {
    _shouldNavigateToTrade = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedQuote = null;
    _shouldNavigateToTrade = false;
    notifyListeners();
  }
}
