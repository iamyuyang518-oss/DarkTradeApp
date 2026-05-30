import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:dark_trade_app/domain/models/achievement.dart';

class AchievementService extends ChangeNotifier {
  static const _boxName = 'achievements';
  Box get _box => Hive.box(_boxName);

  final List<Achievement> _achievements = [];
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<Achievement> get unlocked => _achievements.where((a) => a.unlocked).toList();

  String? _justUnlocked;
  String? get justUnlocked => _justUnlocked;

  AchievementService() {
    _initAchievements();
  }

  void _initAchievements() {
    _achievements.addAll([
      Achievement(id: 'first_trade', name: '新手交易员', emoji: '🍼', description: '完成第一笔交易'),
      Achievement(id: 'first_profit', name: '首次盈利', emoji: '🎯', description: '单笔交易盈利'),
      Achievement(id: 'three_row', name: '连赢三把', emoji: '📈', description: '连续3笔交易盈利'),
      Achievement(id: 'ten_thousand', name: '万元户', emoji: '💰', description: '总资产突破 ¥10,000'),
      Achievement(id: 'ten_trades', name: '交易狂热', emoji: '🔥', description: '单日交易 ≥ 10笔'),
      Achievement(id: 'diamond', name: '钻石手', emoji: '💎', description: '持仓超过7天'),
      Achievement(id: 'bottom_fish', name: '抄底王', emoji: '🦈', description: '当日最低价买入'),
      Achievement(id: 'top_seller', name: '逃顶高手', emoji: '🚀', description: '当日最高价卖出'),
      Achievement(id: 'tutorial', name: '学业有成', emoji: '🎓', description: '完成全部7章教程'),
      Achievement(id: 'stock_god', name: '股神降临', emoji: '👑', description: '总收益率 ≥ 50%'),
    ]);
    _loadState();
  }

  void _loadState() {
    for (final a in _achievements) {
      final unlocked = _box.get(a.id, defaultValue: false) as bool;
      a.unlocked = unlocked;
    }
  }

  void unlock(String id) {
    final a = _achievements.firstWhere((a) => a.id == id);
    if (!a.unlocked) {
      a.unlocked = true;
      a.unlockedAt = DateTime.now();
      _box.put(id, true);
      _justUnlocked = id;
      notifyListeners();
    }
  }

  void clearJustUnlocked() {
    _justUnlocked = null;
  }

  /// Called after each trade to check conditions
  void checkAfterTrade({
    required int totalTrades,
    required int consecutiveWins,
    required double totalReturn,
    required double totalAssets,
    required int todayTradeCount,
  }) {
    if (totalTrades >= 1) unlock('first_trade');
    if (consecutiveWins >= 1) unlock('first_profit');
    if (consecutiveWins >= 3) unlock('three_row');
    if (totalAssets >= 10000) unlock('ten_thousand');
    if (todayTradeCount >= 10) unlock('ten_trades');
    if (totalReturn >= 0.50) unlock('stock_god');
  }

  void checkDiamondHands(int maxHoldDays) {
    if (maxHoldDays > 7) unlock('diamond');
  }

  void checkTutorialComplete() {
    unlock('tutorial');
  }
}
