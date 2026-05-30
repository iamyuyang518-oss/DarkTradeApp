// lib/domain/services/watchlist_service.dart
import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/repositories/watchlist_repository.dart';

class WatchlistService extends ChangeNotifier {
  final HiveWatchlistRepo _localRepo;
  List<String> _symbols = [];
  String? _userId;

  WatchlistService({required HiveWatchlistRepo localRepo})
      : _localRepo = localRepo;

  List<String> get symbols => List.unmodifiable(_symbols);

  Future<void> load({String? userId}) async {
    _userId = userId;
    _symbols = await _localRepo.getWatchedSymbols(userId: userId);
    notifyListeners();
  }

  bool isWatched(String symbol) => _symbols.contains(symbol);

  Future<void> toggleWatch(String symbol) async {
    if (_symbols.contains(symbol)) {
      _symbols.remove(symbol);
      await _localRepo.removeSymbol(symbol, userId: _userId);
    } else {
      _symbols.add(symbol);
      await _localRepo.addSymbol(symbol, userId: _userId);
    }
    notifyListeners();
  }

  /// Called on login — reload from remote/Supabase
  Future<void> onLogin(String userId) async {
    await load(userId: userId);
  }

  /// Called on logout — clear in-memory, reload guest data
  Future<void> onLogout() async {
    _userId = null;
    await load(); // reload guest data
  }
}
