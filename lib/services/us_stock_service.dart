import 'dart:math';

import 'market_data_service.dart';

/// Fetches US stock quotes from Tencent Finance (qt.gtimg.cn).
///
/// Uses HTTPS with no CORS proxy needed — the API returns
/// `Access-Control-Allow-Origin: *`.
class UsStockService extends MarketDataService {
  UsStockService({super.httpClient}) : super(serviceLabel: '美股');

  // ---- configuration -------------------------------------------------------

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  // ---- symbols to fetch ----------------------------------------------------

  /// Popular US stocks displayed in the market explorer.
  static const _symbols = [
    'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'META', 'NVDA', 'TSLA', 'NFLX',
    'JPM', 'BAC', 'GS', 'V', 'MA',
    'JNJ', 'PFE', 'UNH',
    'XOM', 'CVX',
    'WMT', 'KO', 'NKE',
    'BA', 'CAT',
    'BABA', 'AMD', 'INTC', 'DIS', 'PYPL', 'UBER',
  ];

  // ---- sector mapping (for category chip filtering) ------------------------

  static const sectorMap = <String, String>{
    'AAPL': '科技', 'GOOGL': '科技', 'MSFT': '科技', 'AMZN': '科技',
    'META': '科技', 'NVDA': '科技', 'TSLA': '科技', 'NFLX': '科技',
    'BABA': '科技', 'AMD': '科技', 'INTC': '科技',
    'JPM': '金融', 'BAC': '金融', 'GS': '金融', 'V': '金融', 'MA': '金融',
    'JNJ': '医疗', 'PFE': '医疗', 'UNH': '医疗',
    'XOM': '能源', 'CVX': '能源',
    'WMT': '消费', 'KO': '消费', 'NKE': '消费', 'DIS': '消费',
    'BA': '工业', 'CAT': '工业',
    'PYPL': '金融', 'UBER': '科技',
  };

  // ---- API URL -------------------------------------------------------------

  static Uri _buildUri() {
    final codes = _symbols.map((s) => 'us$s').join(',');
    return Uri.parse('https://qt.gtimg.cn/q=$codes');
  }

  // ---- fetchAndParse -------------------------------------------------------

  @override
  Future<ParsedMarkets> fetchAndParse() async {
    final uri = _buildUri();
    final response = await client.get(uri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw MarketsFetchException(
        'Tencent HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'error'}',
      );
    }

    return _parseTencentUs(MarketDataService.decodeTencentResponse(response.body));
  }

  // ---- parsing -------------------------------------------------------------

  /// Parses the Tencent Finance US stock response.
  ///
  /// Response lines look like:
  ///   v_usAAPL="200~Apple~AAPL.OQ~310.85~...~Apple Inc.~...";
  ///
  /// Fields are tilde-separated. Key indices (0-based):
  ///   [2]  = full market code (e.g. "AAPL.OQ")
  ///   [3]  = current price
  ///   [5]  = open
  ///   [6]  = volume
  ///   [33] = change percent
  ///   [34] = high
  ///   [35] = low
  ///   [47] = English name (e.g. "Apple Inc.")
  static ParsedMarkets _parseTencentUs(String body) {
    final quotes = <String, StockQuote>{};
    var volumeSum = 0.0;

    for (final line in body.split('\n')) {
      if (!line.startsWith('v_us')) continue;

      final start = line.indexOf('"');
      final end = line.lastIndexOf('"');
      if (start == -1 || end == -1 || start >= end) continue;

      final values = line.substring(start + 1, end).split('~');
      if (values.length < 48) continue;

      // "AAPL.OQ" → "AAPL"
      final fullCode = values[2];
      final dotIdx = fullCode.indexOf('.');
      final code = dotIdx > 0 ? fullCode.substring(0, dotIdx) : fullCode;

      final price = toDouble(values[3]);
      final changePct = toDouble(values[33]) ?? 0.0;
      final open = toDouble(values[5]) ?? price;
      final high = toDouble(values[34]) ?? price;
      final low = toDouble(values[35]) ?? price;
      final volume = toDouble(values[6]) ?? 0.0;

      if (code.isEmpty || price == null || price <= 0) continue;

      final safeOpen = open ?? price;
      final safeHigh = high ?? price;
      final safeLow = low ?? price;

      // Prefer English name over Chinese (GBK) name.
      final engName = values[47];
      final name = engName.isNotEmpty ? engName : values[1];

      final csv = _buildSparkline(open: safeOpen, high: safeHigh, low: safeLow, last: price);

      quotes[code] = StockQuote(
        id: '${MarketType.usStock}-$code',
        symbol: code,
        name: name.isNotEmpty ? name : code,
        price: price,
        changePct: changePct,
        chartCsv: csv,
        marketType: MarketType.usStock,
      );
      volumeSum += volume;
    }

    // Emit in preferred _symbols order.
    final ordered = <StockQuote>[];
    for (final sym in _symbols) {
      final q = quotes.remove(sym);
      if (q != null) ordered.add(q);
    }
    ordered.addAll(quotes.values);

    return ParsedMarkets(quotes: ordered, totalVolumeUsd: volumeSum);
  }

  // ---- sparkline -----------------------------------------------------------

  static String _buildSparkline({
    required double open,
    required double high,
    required double low,
    required double last,
  }) {
    const n = 8;
    final rng = Random(open.hashCode ^ last.hashCode);
    final points = <double>[];
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final base = open + (last - open) * t;
      final noise = (rng.nextDouble() - 0.5) * 0.02 * base;
      var p = base + noise;
      final lo = (low * 0.99).clamp(0.0, high * 1.01 - 0.01).toDouble();
      final hi = (high * 1.01);
      p = p.clamp(lo, hi).toDouble();
      points.add(p);
    }
    return points.map((e) => e.toStringAsFixed(4)).join(',');
  }
}
