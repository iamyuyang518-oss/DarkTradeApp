import 'package:hive/hive.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';

abstract class TradeHistoryRepository {
  Future<List<TradeRecord>> loadRecords(String careerId);
  Future<void> saveRecord(TradeRecord record);
  Future<void> deleteRecord(String id);
  Future<void> saveAllRecords(List<TradeRecord> records);
  Future<List<TradeRecord>> migrateFromLocal(String careerId);
}

class HiveTradeHistoryRepo implements TradeHistoryRepository {
  static const _boxName = 'tradeHistory';

  Box<TradeRecord> get _box => Hive.box<TradeRecord>(_boxName);

  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async {
    return _box.values.where((r) => r.careerId == careerId).toList();
  }

  @override
  Future<void> saveRecord(TradeRecord record) async {
    await _box.put(record.id, record);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {
    final map = {for (final r in records) r.id: r};
    await _box.putAll(map);
  }

  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async {
    return loadRecords(careerId);
  }
}
