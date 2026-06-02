/// A single ranked entry on the leaderboard — plain Dart, not Hive-persisted.
class LeaderboardEntry {
  final String userId;
  final String username;
  final double totalPnl;
  final double totalReturnRate; // percentage, e.g. 23.5 = 23.5%
  final double winRate; // percentage
  final int totalTrades;
  final int rank; // 1-based display rank
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalPnl,
    required this.totalReturnRate,
    required this.winRate,
    required this.totalTrades,
    required this.rank,
    this.isCurrentUser = false,
  });

  /// Build ranked entries from raw Supabase career rows aggregated per user.
  ///
  /// [rows] = list of maps with keys:
  ///   user_id, total_pnl, initial_balance, total_trades, winning_trades,
  ///   and a nested profiles map: { username }
  static List<LeaderboardEntry> aggregateAndRank(
    List<Map<String, dynamic>> rows, {
    String? currentUserId,
  }) {
    // Group by user_id, accumulate sums
    final Map<String, _Aggregate> groups = {};
    final Map<String, String> usernames = {};

    for (final row in rows) {
      final uid = row['user_id'] as String?;
      if (uid == null || uid.isEmpty) continue;

      final profile = row['profiles'] as Map<String, dynamic>?;
      final username = profile?['username'] as String? ?? '未知用户';

      groups.putIfAbsent(uid, () => _Aggregate());
      final agg = groups[uid]!;
      agg.totalPnl += (row['total_pnl'] as num?)?.toDouble() ?? 0;
      agg.initialBalance +=
          (row['initial_balance'] as num?)?.toDouble() ?? 0;
      agg.totalTrades += (row['total_trades'] as num?)?.toInt() ?? 0;
      agg.winningTrades += (row['winning_trades'] as num?)?.toInt() ?? 0;
      usernames[uid] = username;
    }

    // Build entries, sort by return rate descending
    final entries = <LeaderboardEntry>[];
    for (final entry in groups.entries) {
      final uid = entry.key;
      final agg = entry.value;
      if (agg.initialBalance <= 0) continue;
      final returnRate = (agg.totalPnl / agg.initialBalance) * 100;
      final winRate = agg.totalTrades > 0
          ? (agg.winningTrades / agg.totalTrades) * 100
          : 0.0;
      entries.add(LeaderboardEntry(
        userId: uid,
        username: usernames[uid] ?? '未知用户',
        totalPnl: agg.totalPnl,
        totalReturnRate: returnRate,
        winRate: winRate,
        totalTrades: agg.totalTrades,
        rank: 0, // assigned below
        isCurrentUser: uid == currentUserId,
      ));
    }

    entries.sort((a, b) => b.totalReturnRate.compareTo(a.totalReturnRate));

    // Assign sequential ranks (1-based)
    for (int i = 0; i < entries.length; i++) {
      entries[i] = LeaderboardEntry(
        userId: entries[i].userId,
        username: entries[i].username,
        totalPnl: entries[i].totalPnl,
        totalReturnRate: entries[i].totalReturnRate,
        winRate: entries[i].winRate,
        totalTrades: entries[i].totalTrades,
        rank: i + 1,
        isCurrentUser: entries[i].isCurrentUser,
      );
    }

    return entries;
  }
}

/// Internal aggregation helper.
class _Aggregate {
  double totalPnl = 0;
  double initialBalance = 0;
  int totalTrades = 0;
  int winningTrades = 0;
}
