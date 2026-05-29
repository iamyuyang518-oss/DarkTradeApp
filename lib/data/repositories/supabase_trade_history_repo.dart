import 'package:dark_trade_app/data/local/models/trade_record.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';

class SupabaseTradeHistoryRepo implements TradeHistoryRepository {
  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async {
    final data = await SupabaseClientManager.instance
        .from('trade_records')
        .select()
        .eq('career_id', careerId)
        .order('created_at', ascending: false);
    return _mapList(data);
  }

  List<TradeRecord> _mapList(dynamic data) {
    if (data is! List) return [];
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  TradeType _parseTradeType(String? value) {
    switch (value) {
      case 'sell':
        return TradeType.sell;
      case 'buy':
      default:
        return TradeType.buy;
    }
  }

  MarketType _parseMarketType(String? value) {
    switch (value) {
      case 'usStock':
        return MarketType.usStock;
      case 'aShare':
        return MarketType.aShare;
      case 'crypto':
      default:
        return MarketType.crypto;
    }
  }

  TradeRecord _fromJson(Map<String, dynamic> json) {
    return TradeRecord(
      id: json['id'] as String? ?? '',
      careerId: json['career_id'] as String? ?? '',
      type: _parseTradeType(json['type'] as String?),
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      marketType: _parseMarketType(json['market_type'] as String?),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      pnl: (json['pnl'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _toJson(TradeRecord r, String userId) {
    return {
      'id': r.id,
      'career_id': r.careerId,
      'user_id': userId,
      'type': r.type.name,
      'symbol': r.symbol,
      'name': r.name,
      'market_type': r.marketType.name,
      'quantity': r.quantity,
      'price': r.price,
      'pnl': r.pnl,
      'created_at': r.createdAt.toIso8601String(),
    };
  }

  @override
  Future<void> saveRecord(TradeRecord record) async {
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseClientManager.instance
        .from('trade_records')
        .insert(_toJson(record, userId));
  }

  @override
  Future<void> deleteRecord(String id) async {
    await SupabaseClientManager.instance
        .from('trade_records')
        .delete()
        .eq('id', id);
  }

  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return;
    final rows = records.map((r) => _toJson(r, userId)).toList();
    await SupabaseClientManager.instance.from('trade_records').insert(rows);
  }

  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async {
    return loadRecords(careerId);
  }
}
