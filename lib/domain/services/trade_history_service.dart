import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';

class TradeHistoryService extends ChangeNotifier {
  final TradeHistoryRepository _localRepo;
  TradeHistoryRepository? _remoteRepo;

  List<TradeRecord> _records = [];
  String? _activeCareerId;
  bool _loading = false;

  TradeHistoryService({required TradeHistoryRepository localRepo})
      : _localRepo = localRepo;

  // ---- public getters ----

  List<TradeRecord> get records => List.unmodifiable(_records);

  // ---- login / logout ----

  void setRemoteRepo(TradeHistoryRepository repo) => _remoteRepo = repo;
  void clearRemoteRepo() => _remoteRepo = null;

  // ---- loading ----

  Future<void> loadForCareer(String careerId) async {
    _activeCareerId = careerId;
    _records = await _localRepo.loadRecords(careerId);
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // ---- query (synchronous, from cache) ----

  List<TradeRecord> getRecordsForCareer(String careerId) {
    _ensureLoaded(careerId);
    return List.unmodifiable(_records);
  }

  List<TradeRecord> getRecordsForCareerFiltered(
    String careerId, {
    int days = 0,
  }) {
    final records = getRecordsForCareer(careerId);
    if (days == 0) return records;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records.where((r) => r.createdAt.isAfter(cutoff)).toList();
  }

  void _ensureLoaded(String careerId) {
    if (_activeCareerId != careerId && !_loading) {
      _loading = true;
      _activeCareerId = careerId;
      _localRepo.loadRecords(careerId).then((loaded) {
        _records = loaded..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
        notifyListeners();
      });
    }
  }

  // ---- mutation ----

  Future<void> addRecord(TradeRecord record) async {
    _records.insert(0, record);
    await _localRepo.saveRecord(record);
    _remoteRepo?.saveRecord(record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _localRepo.deleteRecord(id);
    _remoteRepo?.deleteRecord(id);
    notifyListeners();
  }

  // ---- migration ----

  Future<void> migrateLocalToRemote() async {
    if (_remoteRepo == null || _activeCareerId == null) return;
    final local = await _localRepo.migrateFromLocal(_activeCareerId!);
    for (final r in local) {
      await _remoteRepo!.saveRecord(r);
    }
  }
}
