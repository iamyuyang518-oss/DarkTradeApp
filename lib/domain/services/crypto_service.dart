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
    try {
      return await _doFetch();
    } catch (e, st) {
      debugPrint('[CryptoService] fetchAndParse error: $e\n$st');
      rethrow;
    }
  }

  Future<ParsedMarkets> _doFetch() async {
    // Binance public API — supports CORS, no proxy needed
    const baseUrl = 'https://api.binance.com/api/v3/ticker/24hr';
    final uri = Uri.parse(baseUrl);

    debugPrint('[CryptoService] GET $uri');
    final response = await client.get(uri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw MarketsFetchException('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Expected JSON array from Binance');
    }

    // Filter USDT pairs, sort by quote volume, take top 30
    final usdtPairs = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final symbol = item['symbol'];
      if (symbol is String && symbol.endsWith('USDT')) {
        usdtPairs.add(item);
      }
    }

    usdtPairs.sort((a, b) {
      final va = _parseNum(a['quoteVolume']);
      final vb = _parseNum(b['quoteVolume']);
      return vb.compareTo(va);
    });

    final top30 = usdtPairs.take(30).toList();
    if (top30.isEmpty) {
      throw const FormatException('No USDT pairs found in Binance response');
    }

    final quotes = <StockQuote>[];
    double totalVolume = 0;

    for (final coin in top30) {
      try {
        final rawSymbol = coin['symbol']?.toString() ?? '';
        final displaySymbol = rawSymbol.endsWith('USDT')
            ? rawSymbol.substring(0, rawSymbol.length - 4)
            : rawSymbol;

        final price = _parseNum(coin['lastPrice']);
        final changePct = _parseNum(coin['priceChangePercent']);
        final volume = _parseNum(coin['quoteVolume']);
        totalVolume += volume;

        final openPrice = _parseNum(coin['openPrice'], fallback: price);
        final chartCsv = _buildSparkline(openPrice, price);

        quotes.add(StockQuote(
          id: rawSymbol,
          symbol: displaySymbol,
          name: displaySymbol,
          price: price,
          changePct: changePct,
          chartCsv: chartCsv,
          marketType: MarketType.crypto,
        ));
      } catch (e) {
        debugPrint('[CryptoService] skip coin: $e');
        continue;
      }
    }

    if (quotes.isEmpty) {
      throw const FormatException('Failed to parse any crypto quotes');
    }

    return ParsedMarkets(quotes: quotes, totalVolumeUsd: totalVolume);
  }

  /// Parses a numeric value from the Binance API (may be String, int, or double).
  double _parseNum(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Builds an 8-point sparkline between open and close price.
  String _buildSparkline(double open, double close) {
    const points = 8;
    final rand = Random(42);
    final result = <double>[];
    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      final base = open + (close - open) * t;
      final jitter = (rand.nextDouble() - 0.5) * (base * 0.005).abs();
      result.add(base + jitter);
    }
    return result.map((e) => e.toStringAsFixed(4)).join(',');
  }
}
