import 'package:hive/hive.dart';

abstract class WatchlistRepository {
  Future<List<String>> getWatchedSymbols({String? userId});
  Future<void> addSymbol(String symbol, {String? userId});
  Future<void> removeSymbol(String symbol, {String? userId});
  Future<bool> isWatched(String symbol, {String? userId});
  Future<void> clear({String? userId});
}

class HiveWatchlistRepo implements WatchlistRepository {
  static const _boxName = 'watchlist';
  static const _guestKey = '_guest_';

  Box<List> get _box => Hive.box<List>(_boxName);

  String _key(String? userId) => (userId != null && userId.isNotEmpty) ? userId : _guestKey;

  @override
  Future<List<String>> getWatchedSymbols({String? userId}) async {
    final list = _box.get(_key(userId));
    if (list == null) return [];
    return list.cast<String>();
  }

  @override
  Future<void> addSymbol(String symbol, {String? userId}) async {
    final list = await getWatchedSymbols(userId: userId);
    if (!list.contains(symbol)) {
      list.add(symbol);
      await _box.put(_key(userId), list);
    }
  }

  @override
  Future<void> removeSymbol(String symbol, {String? userId}) async {
    final list = await getWatchedSymbols(userId: userId);
    list.remove(symbol);
    await _box.put(_key(userId), list);
  }

  @override
  Future<bool> isWatched(String symbol, {String? userId}) async {
    final list = await getWatchedSymbols(userId: userId);
    return list.contains(symbol);
  }

  @override
  Future<void> clear({String? userId}) async {
    await _box.delete(_key(userId));
  }
}
