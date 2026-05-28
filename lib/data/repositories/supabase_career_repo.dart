import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';

class SupabaseCareerRepo implements CareerRepository {
  @override
  Future<List<Career>> loadCareers() async {
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await SupabaseClientManager.instance
        .from('careers')
        .select()
        .eq('user_id', userId)
        .eq('archived', false);
    return _mapList(data);
  }

  List<Career> _mapList(dynamic data) {
    if (data is! List) return [];
    return data.map((json) => _fromJson(json as Map<String, dynamic>)).toList();
  }

  Career _fromJson(Map<String, dynamic> json) {
    return Career(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      totalPnl: (json['total_pnl'] as num?)?.toDouble() ?? 0,
      totalTrades: (json['total_trades'] as num?)?.toInt() ?? 0,
      winningTrades: (json['winning_trades'] as num?)?.toInt() ?? 0,
      bestTradePnl: (json['best_trade_pnl'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      equityHistory: (json['equity_history'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> _toJson(Career c, String userId) {
    return {
      'id': c.id,
      'user_id': userId,
      'name': c.name,
      'initial_balance': c.initialBalance,
      'current_balance': c.currentBalance,
      'total_pnl': c.totalPnl,
      'total_trades': c.totalTrades,
      'winning_trades': c.winningTrades,
      'best_trade_pnl': c.bestTradePnl,
      'created_at': c.createdAt.toIso8601String(),
      'equity_history': c.equityHistory,
      'archived': false,
    };
  }

  @override
  Future<void> saveCareer(Career career) async {
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
    await SupabaseClientManager.instance
        .from('careers')
        .upsert(_toJson(career, userId));
  }

  @override
  Future<void> deleteCareer(String id) async {
    await SupabaseClientManager.instance
        .from('careers')
        .update({'archived': true})
        .eq('id', id);
  }

  @override
  Future<void> saveAllCareers(List<Career> careers) async {
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
    final rows = careers.map((c) => _toJson(c, userId)).toList();
    await SupabaseClientManager.instance.from('careers').upsert(rows);
  }

  @override
  Future<List<Career>> migrateFromLocal() async {
    return []; // Migration is handled by CareerService
  }
}
