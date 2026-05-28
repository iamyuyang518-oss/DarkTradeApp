import 'dart:convert';
import 'dart:math';

import 'market_data_service.dart';

/// Fetches top US stocks from 东方财富 (East Money) public API.
class UsStockService extends MarketDataService {
  UsStockService({super.httpClient}) : super(serviceLabel: '美股');

  // ---- configuration -------------------------------------------------------

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  // ---- API URL -------------------------------------------------------------

  /// East Money US stock list (NYSE + NASDAQ + AMEX).
  static final Uri _usStockUri = Uri.parse(
    'http://push2.eastmoney.com/api/qt/clist/get'
    '?pn=1&pz=25&po=1&np=1&fltt=2&invt=2&fid=f3'
    '&fs=m:105,m:106,m:107'
    '&fields=f2,f3,f4,f12,f14,f15,f16,f17',
  );

  // ---- sector mapping (for category chip filtering) ------------------------

  static const sectorMap = <String, String>{
    'AAPL': '科技', 'GOOGL': '科技', 'MSFT': '科技', 'AMZN': '科技',
    'META': '科技', 'NVDA': '科技', 'TSLA': '科技', 'NFLX': '科技',
    'JPM': '金融', 'BAC': '金融', 'GS': '金融', 'V': '金融',
    'JNJ': '医疗', 'PFE': '医疗', 'UNH': '医疗',
    'XOM': '能源', 'CVX': '能源',
    'WMT': '消费', 'KO': '消费', 'NKE': '消费',
    'BA': '工业', 'CAT': '工业',
  };

  // ---- fetchAndParse -------------------------------------------------------

  @override
  Future<ParsedMarkets> fetchAndParse() async {
    final uri = MarketDataService.corsProxy(_usStockUri.toString());
    final response = await client.get(uri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw MarketsFetchException(
        'East Money HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'error'}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected East Money response shape');
    }

    return parseEastMoney(decoded, MarketType.usStock);
  }

  // ---- parsing -------------------------------------------------------------

  static ParsedMarkets parseEastMoney(
    Map<String, dynamic> body,
    MarketType marketType,
  ) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing data object in East Money response');
    }

    final diff = data['diff'];
    if (diff is! List<dynamic>) return const ParsedMarkets(quotes: [], totalVolumeUsd: 0);

    final quotes = <StockQuote>[];
    var volumeSum = 0.0;

    for (final raw in diff) {
      if (raw is! Map<String, dynamic>) continue;

      final code = raw['f12'] as String?;
      final name = raw['f14'] as String?;
      final price = toDouble(raw['f2']);
      final changePct = toDouble(raw['f3']) ?? 0.0;

      if (code == null || name == null || price == null || price <= 0) continue;

      final open = toDouble(raw['f17']) ?? price;
      final high = toDouble(raw['f15']) ?? price;
      final low = toDouble(raw['f16']) ?? price;
      final volume = toDouble(raw['f5']) ?? 0.0;

      final csv = _buildSparkline(open: open, high: high, low: low, last: price);

      quotes.add(StockQuote(
        id: '$marketType-$code',
        symbol: code,
        name: name,
        price: price,
        changePct: changePct,
        chartCsv: csv,
        marketType: marketType,
      ));
      volumeSum += volume;
    }

    return ParsedMarkets(quotes: quotes, totalVolumeUsd: volumeSum);
  }

  /// Builds a synthetic 8-point sparkline from OHLC data.
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
      p = p.clamp(low * 0.99, high * 1.01);
      points.add(p);
    }

    return points.map((e) => e.toStringAsFixed(4)).join(',');
  }
}
