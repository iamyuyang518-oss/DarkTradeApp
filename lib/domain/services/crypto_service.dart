import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';

class CryptoService extends MarketDataService {
  CryptoService({super.httpClient}) : super(serviceLabel: '加密货币');

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  @override
  Future<ParsedMarkets> fetchAndParse() async {
    // Binance public API — supports CORS, no proxy needed
    const baseUrl = 'https://api.binance.com/api/v3/ticker/24hr';
    final uri = Uri.parse(baseUrl);

    debugPrint('[CryptoService] GET $uri');
    final response = await client.get(uri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw MarketsFetchException('HTTP ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;

    // Filter USDT pairs, sort by quote volume, take top 30
    final usdtPairs = json
        .where((e) {
          final s = (e as Map<String, dynamic>)['symbol'] as String? ?? '';
          return s.endsWith('USDT');
        })
        .map((e) => e as Map<String, dynamic>)
        .toList();

    usdtPairs.sort((a, b) {
      final va = (a['quoteVolume'] as num?)?.toDouble() ?? 0;
      final vb = (b['quoteVolume'] as num?)?.toDouble() ?? 0;
      return vb.compareTo(va);
    });

    final top30 = usdtPairs.take(30).toList();

    final quotes = <StockQuote>[];
    double totalVolume = 0;

    for (final coin in top30) {
      final rawSymbol = coin['symbol'] as String? ?? '';
      // Strip USDT suffix for display: "BTCUSDT" → "BTC"
      final displaySymbol =
          rawSymbol.endsWith('USDT') ? rawSymbol.substring(0, rawSymbol.length - 4) : rawSymbol;

      final price = (coin['lastPrice'] as num?)?.toDouble() ?? 0;
      final changePct =
          (coin['priceChangePercent'] as num?)?.toDouble() ?? 0;
      final volume =
          (coin['quoteVolume'] as num?)?.toDouble() ?? 0;
      totalVolume += volume;

      // Build a simple sparkline from 24hr open/close
      final openPrice =
          (coin['openPrice'] as num?)?.toDouble() ?? price;
      final chartCsv = _buildSparkline(openPrice, price);

      quotes.add(StockQuote(
        id: rawSymbol, // Binance symbol for K-line lookups
        symbol: displaySymbol,
        name: displaySymbol,
        price: price,
        changePct: changePct,
        chartCsv: chartCsv,
        marketType: MarketType.crypto,
      ));
    }

    return ParsedMarkets(quotes: quotes, totalVolumeUsd: totalVolume);
  }

  /// Builds an 8-point sparkline between open and close price.
  String _buildSparkline(double open, double close) {
    const points = 8;
    final rand = Random(42); // seeded for consistency per fetch
    final result = <double>[];
    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      // Linear interpolation + small jitter
      final base = open + (close - open) * t;
      final jitter = (rand.nextDouble() - 0.5) * (base * 0.005).abs();
      result.add(base + jitter);
    }
    return result.map((e) => e.toStringAsFixed(4)).join(',');
  }
}
