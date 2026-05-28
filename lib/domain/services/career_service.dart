import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';

class CareerService extends ChangeNotifier {
  final CareerRepository _localRepo;
  CareerRepository? _remoteRepo;
  final TradeHistoryRepository _tradeHistoryRepo;

  List<Career> _careers = [];
  Career? _activeCareer;
  bool _isLoggedIn = false;

  CareerService({
    required CareerRepository localRepo,
    required TradeHistoryRepository tradeHistoryRepo,
  })  : _localRepo = localRepo,
       _tradeHistoryRepo = tradeHistoryRepo;

  // ---- public getters ----

  List<Career> get careers => List.unmodifiable(_careers);
  Career? get activeCareer => _activeCareer;
  bool get isLoggedIn => _isLoggedIn;

  // ---- init ----

  Future<void> load() async {
    _careers = await _localRepo.loadCareers();
    if (_careers.isNotEmpty) {
      _activeCareer = _careers.first;
    } else {
      _activeCareer = _createDefaultCareer();
    }
    notifyListeners();
  }

  // ---- login / logout ----

  void setRemoteRepo(CareerRepository repo) {
    _remoteRepo = repo;
    _isLoggedIn = true;
  }

  void clearRemoteRepo() {
    _remoteRepo = null;
    _isLoggedIn = false;
  }

  // ---- internal helpers ----

  Career _createDefaultCareer() {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '生涯 #1',
      initialBalance: 100000,
    );
    _careers.add(career);
    _localRepo.saveCareer(career);
    _remoteRepo?.saveCareer(career);
    return career;
  }

  Future<void> _saveActiveCareer() async {
    final c = _activeCareer;
    if (c != null) {
      await _localRepo.saveCareer(c);
      await _remoteRepo?.saveCareer(c);
    }
  }

  // ---- CRUD ----

  Future<Career> createCareer(String name, double initialBalance) async {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      initialBalance: initialBalance.clamp(1, 100000000),
    );
    _careers.add(career);
    await _localRepo.saveCareer(career);
    _remoteRepo?.saveCareer(career);
    notifyListeners();
    return career;
  }

  void switchCareer(String careerId) {
    final idx = _careers.indexWhere((c) => c.id == careerId);
    if (idx >= 0) {
      _activeCareer = _careers[idx];
      notifyListeners();
    }
  }

  Future<void> deleteCareer(String careerId) async {
    if (_careers.length <= 1) return;
    _careers.removeWhere((c) => c.id == careerId);
    await _localRepo.deleteCareer(careerId);
    _remoteRepo?.deleteCareer(careerId);

    // Also delete associated trade records
    final records = await _tradeHistoryRepo.loadRecords(careerId);
    for (final r in records) {
      await _tradeHistoryRepo.deleteRecord(r.id);
    }

    if (_activeCareer?.id == careerId) {
      _activeCareer = _careers.isNotEmpty ? _careers.first : null;
    }
    notifyListeners();
  }

  // ---- balance / P&L ----

  void updateBalance(double newBalance) {
    _activeCareer?.recordEquitySnapshot(newBalance);
    _saveActiveCareer();
    notifyListeners();
  }

  void recordPnl(double pnl) {
    _activeCareer?.recordTrade(pnl);
    _saveActiveCareer();
    notifyListeners();
  }

  // ---- bulk update (e.g. after external mutation) ----

  Future<void> updateActiveCareer(Career updated) async {
    final idx = _careers.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _careers[idx] = updated;
      _activeCareer = updated;
      await _localRepo.saveCareer(updated);
      _remoteRepo?.saveCareer(updated);
      notifyListeners();
    }
  }

  // ---- migration ----

  Future<void> migrateLocalToRemote() async {
    if (_remoteRepo == null) return;
    final localCareers = await _localRepo.migrateFromLocal();
    for (final c in localCareers) {
      await _remoteRepo!.saveCareer(c);
    }
  }
}
