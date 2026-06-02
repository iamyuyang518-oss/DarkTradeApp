import 'package:dark_trade_app/data/models/leaderboard_entry.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';

enum LeaderboardPeriod { weekly, monthly, allTime }

abstract class LeaderboardRepository {
  /// Returns ranked entries for the given period, limited to [limit].
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardPeriod period,
    String? currentUserId,
    int limit = 50,
  });
}

class SupabaseLeaderboardRepo implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardPeriod period,
    String? currentUserId,
    int limit = 50,
  }) async {
    var query = SupabaseClientManager.instance
        .from('careers')
        .select(
            'user_id, total_pnl, initial_balance, total_trades, winning_trades, profiles!inner(username)')
        .eq('archived', false);

    // Filter by created_at for weekly / monthly periods
    if (period == LeaderboardPeriod.weekly) {
      final weekStart = _startOfWeek();
      query = query.gte('created_at', weekStart.toIso8601String());
    } else if (period == LeaderboardPeriod.monthly) {
      final monthStart = _startOfMonth();
      query = query.gte('created_at', monthStart.toIso8601String());
    }

    final data = await query;

    final raw = (data as List).cast<Map<String, dynamic>>();
    final all = LeaderboardEntry.aggregateAndRank(raw,
        currentUserId: currentUserId);

    return all.take(limit).toList();
  }

  DateTime _startOfWeek() {
    final now = DateTime.now();
    // Monday of current week
    final daysSinceMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysSinceMonday);
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
}
