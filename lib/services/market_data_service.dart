import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Distinguishes between the three supported markets.
enum MarketType { crypto, usStock, aShare }

/// A single quote row displayed in the market explorer.
@immutable
class StockQuote {
  const StockQuote({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
    required this.chartCsv,
    required this.marketType,
  });

  /// Unique identifier (exchange-dependent: Binance symbol, stock code, etc.).
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double changePct;
  final String chartCsv;
  final MarketType marketType;

  String get priceLabel {
    if (price >= 1000) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(4);
    if (price >= 0.01) return price.toStringAsFixed(6);
    return price.toStringAsFixed(8);
  }

  String get changeLabel {
    final sign = changePct >= 0 ? '+' : '';
    return '$sign${changePct.toStringAsFixed(2)}%';
  }

  bool get isUp => changePct >= 0;
}

/// A single OHLC bar for K-line chart display.
class KlineBar {
  const KlineBar({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  bool get isUp => close >= open;
}

/// Internal container returned by [MarketDataService.fetchAndParse].
class ParsedMarkets {
  const ParsedMarkets({required this.quotes, required this.totalVolumeUsd});

  final List<StockQuote> quotes;
  final double totalVolumeUsd;
}

/// Thrown when an HTTP fetch returns a non-200 status.
class MarketsFetchException implements Exception {
  MarketsFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Shared utility helpers
// ---------------------------------------------------------------------------

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Downsamples long sparkline arrays so chart rows stay readable.
String sparklineToCsv(List<double> prices, {required double fallbackPrice}) {
  if (prices.isEmpty) {
    return List<double>.filled(8, fallbackPrice)
        .map((e) => e.toStringAsFixed(4))
        .join(',');
  }

  const targetPoints = 24;
  final sampled = prices.length <= targetPoints
      ? prices
      : List<double>.generate(targetPoints, (i) {
          final idx = (i * (prices.length - 1) / (targetPoints - 1)).round();
          return prices[idx];
        });

  return sampled.map((e) => e.toStringAsFixed(4)).join(',');
}

String friendlyError(Object e) {
  final msg = e.toString();
  if (msg.contains('SocketException') ||
      msg.contains('Failed host lookup') ||
      msg.contains('Network is unreachable')) {
    return '网络已断开';
  }
  if (msg.contains('TimeoutException')) {
    return '请求超时';
  }
  if (msg.contains('429')) {
    return '请求过于频繁，请稍后再试';
  }
  return msg.length > 120 ? '${msg.substring(0, 120)}…' : msg;
}

String formatTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ---------------------------------------------------------------------------
// K-line fetcher
// ---------------------------------------------------------------------------

/// Fetches daily K-line bars for a given stock/crypto.
/// [stockId] is the raw identifier: Binance symbol, or numeric code for stocks.
Future<List<KlineBar>> fetchKline(
  String stockId,
  MarketType marketType, {
  int limit = 90,
  http.Client? client,
}) async {
  late final Uri uri;
  switch (marketType) {
    case MarketType.crypto:
      uri = Uri.https('data-api.binance.vision', '/api/v3/klines', {
        'symbol': stockId,
        'interval': '1d',
        'limit': limit.toString(),
      });
      break;
    case MarketType.usStock:
      final code = stockId.split('-').last;
      // Tencent API: usAAPL,day,,,90,qfq → data.usAAPL.day
      uri = Uri.https('web.ifzq.gtimg.cn', '/appstock/app/fqkline/get', {
        'param': 'us$code,day,,,$limit,qfq',
      });
      break;
    case MarketType.aShare:
      final code = stockId.split('-').last;
      // Tencent API: sh600519 or sz000001 based on code prefix
      final prefix = code.startsWith('6') ? 'sh' : 'sz';
      // A-shares return data.{prefix}{code}.qfqday
      uri = Uri.https('web.ifzq.gtimg.cn', '/appstock/app/fqkline/get', {
        'param': '$prefix$code,day,,,$limit,qfq',
      });
      break;
  }

  debugPrint('[fetchKline] GET $uri');
  final resp = client != null
      ? await client.get(uri).timeout(const Duration(seconds: 10))
      : await http.get(uri).timeout(const Duration(seconds: 10));

  if (resp.statusCode != 200) {
    debugPrint('[fetchKline] HTTP ${resp.statusCode}');
    throw MarketsFetchException('HTTP ${resp.statusCode}');
  }

  final result = _parseKlineResponse(resp.body, marketType);
  debugPrint('[fetchKline] parsed ${result.length} bars');
  return result;
}

List<KlineBar> _parseKlineResponse(String body, MarketType marketType) {
  switch (marketType) {
    case MarketType.crypto:
      return _parseBinanceKlines(body);
    case MarketType.usStock:
    case MarketType.aShare:
      return _parseTencentKlines(body, marketType);
  }
}

List<KlineBar> _parseBinanceKlines(String body) {
  final list = jsonDecode(body) as List<dynamic>;
  return list.map((e) {
    final arr = e as List<dynamic>;
    return KlineBar(
      date: DateTime.fromMillisecondsSinceEpoch(arr[0] as int),
      open: double.tryParse((arr[1] as String? ?? '')) ?? 0,
      high: double.tryParse((arr[2] as String? ?? '')) ?? 0,
      low: double.tryParse((arr[3] as String? ?? '')) ?? 0,
      close: double.tryParse((arr[4] as String? ?? '')) ?? 0,
      volume: double.tryParse((arr[5] as String? ?? '')) ?? 0,
    );
  }).toList();
}

/// Parses Tencent Finance K-line response for US stocks and A-shares.
/// US stocks: data.usAAPL.day → [[date, open, close, high, low, volume], ...]
/// A-shares: data.sh600519.qfqday → [[date, open, close, high, low, volume], ...]
List<KlineBar> _parseTencentKlines(String body, MarketType marketType) {
  final map = jsonDecode(body) as Map<String, dynamic>;
  final data = map['data'] as Map<String, dynamic>?;
  if (data == null || data.isEmpty) return [];

  List<dynamic>? raw;
  if (marketType == MarketType.usStock) {
    // US: find the first key that ends with '.day'
    for (final k in data.keys) {
      if (k.endsWith('.day')) {
        raw = data[k] as List<dynamic>?;
        break;
      }
    }
  } else {
    // A-share: find the key that ends with '.qfqday'
    for (final k in data.keys) {
      if (k.endsWith('.qfqday')) {
        raw = data[k] as List<dynamic>?;
        break;
      }
    }
  }
  if (raw == null || raw.isEmpty) return [];

  return raw.map((e) {
    final arr = e as List<dynamic>;
    // Format: [date_string, open, close, high, low, volume]
    return KlineBar(
      date: DateTime.tryParse(arr[0] as String? ?? '') ?? DateTime(0),
      open: toDouble(arr[1]) ?? 0,
      close: toDouble(arr[2]) ?? 0,
      high: toDouble(arr[3]) ?? 0,
      low: toDouble(arr[4]) ?? 0,
      volume: toDouble(arr[5]) ?? 0,
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// Abstract base class shared by all three market data services
// ---------------------------------------------------------------------------

abstract class MarketDataService extends ChangeNotifier {
  MarketDataService({http.Client? httpClient, this.serviceLabel = ''})
      : _ownsClient = httpClient == null {
    _client = httpClient ?? http.Client();
  }

  /// Human-readable label for the service (e.g. "加密货币", "美股").
  final String serviceLabel;

  /// Refresh interval — subclasses override to tune frequency.
  Duration get refreshInterval;

  /// HTTP request timeout — subclasses may override.
  Duration get requestTimeout => const Duration(seconds: 15);

  final bool _ownsClient;
  late final http.Client _client;

  Timer? _refreshTimer;
  bool _started = false;
  bool _fetchInFlight = false;

  List<StockQuote> quotes = [];
  double totalVolumeUsd = 0;

  /// Human-readable status: success message, error, or stale-cache notice.
  String? lastNetworkNote;

  /// Last error message when a fetch fails (may still show cached [quotes]).
  String? lastError;

  DateTime? lastSuccessfulFetchAt;

  bool get isUsingCachedData => lastError != null && quotes.isNotEmpty;

  http.Client get client => _client;

  /// Starts initial fetch and periodic refresh.
  void start() {
    if (_started) return;
    _started = true;
    unawaited(refresh());
    _refreshTimer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
  }

  /// Template method: calls [fetchAndParse], updates public state, handles
  /// errors.
  Future<void> refresh() async {
    if (_fetchInFlight) return;
    _fetchInFlight = true;

    try {
      final parsed = await fetchAndParse();
      if (parsed.quotes.isEmpty) {
        throw const FormatException('No valid market entries in response');
      }

      quotes = parsed.quotes;
      totalVolumeUsd = parsed.totalVolumeUsd;
      lastSuccessfulFetchAt = DateTime.now();
      lastError = null;
      lastNetworkNote =
          '${serviceLabel}行情已更新 · ${parsed.quotes.length} 条 · ${formatTime(lastSuccessfulFetchAt!)}';
      notifyListeners();
    } catch (e, st) {
      debugPrint('$serviceLabel refresh failed: $e\n$st');
      lastError = friendlyError(e);

      if (quotes.isNotEmpty) {
        lastNetworkNote = '网络异常，显示上次数据（$lastError）';
      } else {
        lastNetworkNote = '无法加载${serviceLabel}行情：$lastError';
      }
      notifyListeners();
    } finally {
      _fetchInFlight = false;
    }
  }

  /// Subclasses implement the actual HTTP request + parsing. Must return at
  /// least one quote (or throw).
  Future<ParsedMarkets> fetchAndParse();

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }
}
