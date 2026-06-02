import 'package:flutter/foundation.dart';

enum SentimentLevel { zen, popcorn, fire }

class MarketSentiment {
  final SentimentLevel level;
  final double avgVolatility;
  final String emoji;
  final String label;
  final String hint;

  const MarketSentiment({
    required this.level,
    required this.avgVolatility,
    required this.emoji,
    required this.label,
    required this.hint,
  });
}

class MarketSentimentService extends ChangeNotifier {
  MarketSentiment _marketSentiment = const MarketSentiment(
    level: SentimentLevel.popcorn,
    avgVolatility: 0.0,
    emoji: '🍿',
    label: '吃瓜看戏',
    hint: '加载中...',
  );

  MarketSentiment get marketSentiment => _marketSentiment;

  /// Compute market-level sentiment from a list of absolute change percentages.
  void computeMarket(List<double> absChanges) {
    if (absChanges.isEmpty) return;

    final avg = absChanges.reduce((a, b) => a + b) / absChanges.length;

    final SentimentLevel level;
    final String emoji;
    final String label;
    final String hint;

    if (avg < 0.5) {
      level = SentimentLevel.zen;
      emoji = '🧘';
      label = '佛系';
      hint = '市场风平浪静，适合慢慢研究';
    } else if (avg < 2.0) {
      level = SentimentLevel.popcorn;
      emoji = '🍿';
      label = '吃瓜看戏';
      hint = '小幅波动，市场正在寻找方向';
    } else {
      level = SentimentLevel.fire;
      emoji = '🔥';
      label = '上头';
      hint = '波动较大，多看少动，注意风险';
    }

    final newSentiment = MarketSentiment(
      level: level,
      avgVolatility: avg,
      emoji: emoji,
      label: label,
      hint: hint,
    );

    if (newSentiment.level != _marketSentiment.level ||
        (newSentiment.avgVolatility - _marketSentiment.avgVolatility).abs() > 0.1) {
      _marketSentiment = newSentiment;
      notifyListeners();
    }
  }

  /// Compute user-level sentiment from recent trade count.
  SentimentLevel userSentiment(int recentTradeCount) {
    if (recentTradeCount <= 1) return SentimentLevel.zen;
    if (recentTradeCount <= 5) return SentimentLevel.popcorn;
    return SentimentLevel.fire;
  }
}
