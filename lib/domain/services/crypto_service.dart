import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dark_trade_app/domain/services/market_data_service.dart';

class CryptoService extends MarketDataService {
  CryptoService({super.httpClient}) : super(serviceLabel: '加密货币');

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  @override
  Future<ParsedMarkets> fetchAndParse() async {
    // CoinGecko free API: top 30 coins by market cap, CNY prices, 7d sparkline
    const baseUrl = 'https://api.coingecko.com/api/v3/coins/markets';
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'vs_currency': 'cny',
      'order': 'market_cap_desc',
      'per_page': '30',
      'page': '1',
      'sparkline': 'true',
      'price_change_percentage': '24h',
    });

    // Try direct first — CoinGecko allows browser CORS for public endpoints.
    // Fall back to CORS proxy only if direct fails with a non-403 error.
    http.Response response;
    try {
      debugPrint('[CryptoService] GET $uri');
      response = await client.get(uri).timeout(requestTimeout);
    } catch (_) {
      // Direct failed — try via CORS proxy
      final proxied = MarketDataService.corsProxy(uri.toString());
      debugPrint('[CryptoService] direct failed, trying proxy: $proxied');
      response = await client.get(proxied).timeout(requestTimeout);
    }

    if (response.statusCode != 200) {
      throw MarketsFetchException('HTTP ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;

    final quotes = <StockQuote>[];
    double totalVolume = 0;

    for (final coin in json) {
      final map = coin as Map<String, dynamic>;
      final symbol = map['symbol'] as String? ?? '';
      final name = map['name'] as String? ?? symbol;

      final price = (map['current_price'] as num?)?.toDouble() ?? 0;
      final changePct =
          (map['price_change_percentage_24h'] as num?)?.toDouble() ?? 0;

      // 7-day sparkline
      final sparkline = map['sparkline_in_7d'] as Map<String, dynamic>?;
      final prices = (sparkline?['price'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [];

      final chartCsv =
          sparklineToCsv(prices, fallbackPrice: price);

      final volume =
          (map['total_volume'] as num?)?.toDouble() ?? 0;
      totalVolume += volume;

      // Use CoinGecko id as the stock identifier for K-line lookups
      final id = map['id'] as String? ?? symbol;

      quotes.add(StockQuote(
        id: id,
        symbol: symbol.toUpperCase(),
        name: name,
        price: price,
        changePct: changePct,
        chartCsv: chartCsv,
        marketType: MarketType.crypto,
      ));
    }

    return ParsedMarkets(quotes: quotes, totalVolumeUsd: totalVolume);
  }
}
