import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/models/leaderboard_entry.dart';
import 'package:dark_trade_app/data/repositories/leaderboard_repository.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';

class LeaderboardService extends ChangeNotifier {
  final LeaderboardRepository _repo = SupabaseLeaderboardRepo();

  List<LeaderboardEntry> _entries = [];
  LeaderboardPeriod _period = LeaderboardPeriod.allTime;
  bool _isLoading = false;
  String? _error;
  LeaderboardEntry? _currentUserEntry;
  bool _currentUserInList = false;

  // --- public getters ---

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  LeaderboardPeriod get period => _period;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LeaderboardEntry? get currentUserEntry => _currentUserEntry;
  bool get currentUserInList => _currentUserInList;

  // --- period switching ---

  Future<void> setPeriod(LeaderboardPeriod p) async {
    if (_period == p) return;
    _period = p;
    notifyListeners();
    await fetchLeaderboard();
  }

  // --- fetch ---

  Future<void> fetchLeaderboard() async {
    final uid = SupabaseClientManager.instance.auth.currentUser?.id;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch top 50
      _entries = await _repo.fetchLeaderboard(
        period: _period,
        currentUserId: uid,
        limit: 50,
      );

      // Determine if current user is in the top 50
      _currentUserInList = _entries.any((e) => e.isCurrentUser);
      _currentUserEntry = _currentUserInList
          ? _entries.firstWhere((e) => e.isCurrentUser)
          : null;

      // If user is logged in but not in top 50, fetch their specific rank
      if (uid != null && !_currentUserInList) {
        final allEntries = await _repo.fetchLeaderboard(
          period: _period,
          currentUserId: uid,
          limit: 9999,
        );
        final self = allEntries.where((e) => e.isCurrentUser).toList();
        if (self.isNotEmpty) {
          _currentUserEntry = self.first;
        }
      }

      _error = null;
    } catch (e) {
      debugPrint('[LeaderboardService] fetch error: $e');
      _error = '加载排行榜失败，请检查网络连接';
      _entries = [];
      _currentUserEntry = null;
      _currentUserInList = false;
    }

    _isLoading = false;
    notifyListeners();
  }
}
