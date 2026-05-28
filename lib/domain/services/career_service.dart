import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/local/hive_service.dart';

class CareerService extends ChangeNotifier {
  Career? _activeCareer;
  List<Career> get careers => HiveService.careers.values.toList();
  Career? get activeCareer => _activeCareer;

  CareerService() {
    if (careers.isEmpty) {
      _activeCareer = _createDefaultCareer();
    } else {
      _activeCareer = careers.first;
    }
  }

  Career _createDefaultCareer() {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '生涯 #1',
      initialBalance: 100000,
    );
    HiveService.careers.put(career.id, career);
    notifyListeners();
    return career;
  }

  Career createCareer(String name, double initialBalance) {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      initialBalance: initialBalance.clamp(1, 100000000),
    );
    HiveService.careers.put(career.id, career);
    notifyListeners();
    return career;
  }

  void switchCareer(String careerId) {
    final career = HiveService.careers.get(careerId);
    if (career != null) {
      _activeCareer = career;
      notifyListeners();
    }
  }

  void deleteCareer(String careerId) {
    if (careers.length <= 1) return;
    HiveService.careers.delete(careerId);
    if (_activeCareer?.id == careerId) {
      _activeCareer = careers.first;
    }
    final records = HiveService.tradeHistory.values
        .where((r) => r.careerId == careerId)
        .toList();
    for (final r in records) {
      HiveService.tradeHistory.delete(r.id);
    }
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    _activeCareer?.recordEquitySnapshot(newBalance);
    _activeCareer?.save();
    notifyListeners();
  }

  void recordPnl(double pnl) {
    _activeCareer?.recordTrade(pnl);
    _activeCareer?.save();
    notifyListeners();
  }
}
