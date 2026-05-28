import 'dart:convert';
import 'dart:math';

import 'market_data_service.dart';

/// Fetches top 20 crypto pairs from Binance public API.
///
/// Uses the data-api subdomain which is typically accessible inside China.
class LiveMarketService extends MarketDataService {
  LiveMarketService({super.httpClient})
      : super(serviceLabel: '加密货币');

  // ---- configuration -------------------------------------------------------

  @override
  Duration get refreshInterval => const Duration(seconds: 60);

  // ---- API URLs ------------------------------------------------------------

  /// 24hr ticker for every symbol on Binance.
  static final Uri _tickerUri = Uri.parse(
    'https://data-api.binance.vision/api/v3/ticker/24hr',
  );

  /// List of preferred symbols (top 20 USDT pairs by market cap / volume).
  /// These are used to order results so the most interesting coins appear
  /// first regardless of the ticker sort order.
  static const _preferredSymbols = [
    'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT',
    'ADAUSDT', 'DOGEUSDT', 'AVAXUSDT', 'DOTUSDT', 'LINKUSDT',
    'MATICUSDT', 'UNIUSDT', 'SHIBUSDT', 'LTCUSDT', 'ATOMUSDT',
    'ETCUSDT', 'XLMUSDT', 'FILUSDT', 'TRXUSDT', 'NEARUSDT',
  ];

  // ---- fetchAndParse -------------------------------------------------------

  @override
  Future<ParsedMarkets> fetchAndParse() async {
    final response = await client.get(_tickerUri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw MarketsFetchException(
        'Binance HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'error'}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Unexpected Binance response shape');
    }

    return _parseBinance(decoded);
  }

  // ---- parsing -------------------------------------------------------------

  static ParsedMarkets _parseBinance(List<dynamic> list) {
    // Build a lookup map for all USDT pairs.
    final allUsdt = <String, Map<String, dynamic>>{};
    for (final raw in list) {
      if (raw is! Map<String, dynamic>) continue;
      final symbol = raw['symbol'] as String?;
      if (symbol == null || !symbol.endsWith('USDT')) continue;
      allUsdt[symbol] = raw;
    }

    final quotes = <StockQuote>[];
    var volumeSum = 0.0;

    // First emit the preferred symbols in the defined order.
    for (final symbol in _preferredSymbols) {
      final raw = allUsdt.remove(symbol);
      if (raw == null) continue;
      final q = _makeQuote(raw, symbol);
      if (q != null) {
        quotes.add(q);
        volumeSum += _volumeFromRaw(raw);
      }
    }

    // Then append remaining USDT pairs sorted by quote volume descending.
    final remaining = allUsdt.entries.toList()
      ..sort((a, b) {
        final va = _volumeFromRaw(b.value);
        final vb = _volumeFromRaw(a.value);
        return vb.compareTo(va);
      });

    for (final entry in remaining) {
      final q = _makeQuote(entry.value, entry.key);
      if (q != null) {
        quotes.add(q);
        volumeSum += _volumeFromRaw(entry.value);
      }
      if (quotes.length >= 20) break;
    }

    return ParsedMarkets(quotes: quotes, totalVolumeUsd: volumeSum);
  }

  static StockQuote? _makeQuote(Map<String, dynamic> raw, String symbol) {
    final price = toDouble(raw['lastPrice']);
    if (price == null || price <= 0) return null;

    final changePct = toDouble(raw['priceChangePercent']) ?? 0.0;
    final open = toDouble(raw['openPrice']) ?? price;
    final high = toDouble(raw['highPrice']) ?? price;
    final low = toDouble(raw['lowPrice']) ?? price;
    final baseAsset = symbol.replaceAll('USDT', '');

    final csv = _buildSparkline(open: open, high: high, low: low, last: price);

    return StockQuote(
      id: symbol,
      symbol: baseAsset,
      name: baseAsset,
      price: price,
      changePct: changePct,
      chartCsv: csv,
      marketType: MarketType.crypto,
    );
  }

  static double _volumeFromRaw(Map<String, dynamic> raw) {
    return toDouble(raw['quoteVolume']) ?? 0.0;
  }

  /// Builds a synthetic 8-point sparkline from 24h OHLC data so every row
  /// has a visual trend matching real price direction.
  static String _buildSparkline({
    required double open,
    required double high,
    required double low,
    required double last,
  }) {
    const n = 8;
    final rng = Random(open.hashCode ^ last.hashCode);
    final points = <double>[];

    // Walk through 8 time slots, interpolating from open to last with gentle
    // noise that stays within [low, high].
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final base = open + (last - open) * t;
      // Add ±1% noise clamped to the day's range.
      final noise = (rng.nextDouble() - 0.5) * 0.02 * base;
      var p = base + noise;
      p = p.clamp(low * 0.99, high * 1.01);
      points.add(p);
    }

    return points.map((e) => e.toStringAsFixed(4)).join(',');
  }
}
