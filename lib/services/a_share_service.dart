import 'dart:math';

import 'market_data_service.dart';

/// Fetches A-share quotes from Tencent Finance (qt.gtimg.cn).
///
/// Uses HTTPS with no CORS proxy needed — the API returns
/// `Access-Control-Allow-Origin: *`.
class AShareService extends MarketDataService {
  AShareService({super.httpClient}) : super(serviceLabel: 'A股');

  // ---- configuration -------------------------------------------------------

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  // ---- symbols to fetch ----------------------------------------------------

  /// Popular A-shares displayed in the market explorer.
  /// Each entry is the full Tencent code: "sh" + 6 digits or "sz" + 6 digits.
  static const _codes = [
    // Shanghai main board
    'sh600519', 'sh601318', 'sh600036', 'sh600030', 'sh601166',
    'sh600887', 'sh601088', 'sh600900', 'sh601857', 'sh600276',
    'sh600585', 'sh601398', 'sh600809',
    // Shenzhen main / SME
    'sz000001', 'sz000858', 'sz000002', 'sz000333', 'sz002594',
    'sz000651', 'sz002415', 'sz000568', 'sz002475', 'sz000725',
    // ChiNext / STAR
    'sz300750', 'sz300059', 'sh688981', 'sh688111',
  ];

  // ---- sector mapping (by prefix ranges) -----------------------------------

  /// Maps A-share codes to sector labels for category chip filtering.
  static String sectorForCode(String code) {
    if (code.startsWith('600') || code.startsWith('601') || code.startsWith('603')) {
      if (code.startsWith('6019') || code.startsWith('6000')) return '金融';
      if (code.startsWith('6005') || code.startsWith('603')) return '科技';
      if (code.startsWith('6002') || code.startsWith('6007')) return '医药';
      if (code.startsWith('6008')) return '消费';
      if (code.startsWith('6018')) return '能源';
      if (code.startsWith('6013')) return '金融';
      return '综合';
    }
    if (code.startsWith('000') || code.startsWith('001') || code.startsWith('002')) {
      if (code.startsWith('0008') || code.startsWith('0027')) return '金融';
      if (code.startsWith('0024') || code.startsWith('0020')) return '科技';
      if (code.startsWith('0005') || code.startsWith('0020')) return '医药';
      if (code.startsWith('0008') && code.length > 3 && code[3] == '5') return '消费';
      if (code.startsWith('0009')) return '能源';
      return '综合';
    }
    if (code.startsWith('300') || code.startsWith('688')) {
      if (code.startsWith('688')) return '科技';
      if (code.startsWith('3007') || code.startsWith('3005')) return '科技';
      if (code.startsWith('3000') || code.startsWith('3002')) return '医药';
      if (code.startsWith('3004') || code.startsWith('3006')) return '金融';
      return '科技';
    }
    return '综合';
  }

  // ---- API URL -------------------------------------------------------------

  static Uri _buildUri() {
    return Uri.parse('https://qt.gtimg.cn/q=${_codes.join(',')}');
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

    return _parseTencentAShare(MarketDataService.decodeTencentResponse(response.body));
  }

  // ---- parsing -------------------------------------------------------------

  /// Parses the Tencent Finance A-share response.
  ///
  /// Response lines look like:
  ///   v_sh600519="1~贵州茅台~600519~1275.98~...";
  ///   v_sz000001="51~平安银行~000001~10.66~...";
  ///
  /// Fields are tilde-separated. Key indices (0-based):
  ///   [1]  = Chinese name
  ///   [2]  = 6-digit code
  ///   [3]  = current price
  ///   [5]  = open
  ///   [6]  = volume (lots)
  ///   [32] = change percent
  ///   [33] = high
  ///   [34] = low
  static ParsedMarkets _parseTencentAShare(String body) {
    final quotes = <String, StockQuote>{};
    var volumeSum = 0.0;

    for (final line in body.split('\n')) {
      if (!line.startsWith('v_sh') && !line.startsWith('v_sz')) continue;

      final start = line.indexOf('"');
      final end = line.lastIndexOf('"');
      if (start == -1 || end == -1 || start >= end) continue;

      final values = line.substring(start + 1, end).split('~');
      if (values.length < 35) continue;

      final code = values[2];
      final price = toDouble(values[3]);
      final changePct = toDouble(values[32]) ?? 0.0;
      final open = toDouble(values[5]) ?? price;
      final high = toDouble(values[33]) ?? price;
      final low = toDouble(values[34]) ?? price;
      // A-share volume is reported in lots (手), each lot = 100 shares.
      final volume = (toDouble(values[6]) ?? 0.0) * 100;

      if (code.isEmpty || price == null || price <= 0) continue;

      final safeOpen = open ?? price;
      final safeHigh = high ?? price;
      final safeLow = low ?? price;

      final name = values[1];
      final csv = _buildSparkline(open: safeOpen, high: safeHigh, low: safeLow, last: price);

      quotes[code] = StockQuote(
        id: '${MarketType.aShare}-$code',
        symbol: code,
        name: name.isNotEmpty ? name : code,
        price: price,
        changePct: changePct,
        chartCsv: csv,
        marketType: MarketType.aShare,
      );
      volumeSum += volume;
    }

    // Emit in preferred _codes order (strip prefix for matching).
    final ordered = <StockQuote>[];
    for (final fullCode in _codes) {
      final code = fullCode.substring(2); // "sh600519" → "600519"
      final q = quotes.remove(code);
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
