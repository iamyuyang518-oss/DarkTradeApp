import 'package:flutter/foundation.dart';
import '../data/local/models/trade_record.dart';
import '../data/local/hive_service.dart';

class TradeHistoryService extends ChangeNotifier {
  List<TradeRecord> getRecordsForCareer(String careerId) {
    return HiveService.tradeHistory.values
        .where((r) => r.careerId == careerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  void addRecord(TradeRecord record) {
    HiveService.tradeHistory.put(record.id, record);
    notifyListeners();
  }
}
