import 'dart:convert';

import 'market_data_service.dart';
import 'us_stock_service.dart';

/// Fetches top A-shares from 东方财富 (East Money) public API.
class AShareService extends MarketDataService {
  AShareService({super.httpClient}) : super(serviceLabel: 'A股');

  // ---- configuration -------------------------------------------------------

  @override
  Duration get refreshInterval => const Duration(seconds: 30);

  // ---- API URL -------------------------------------------------------------

  /// East Money A-share list (Shanghai + Shenzhen).
  static final Uri _aShareUri = Uri.parse(
    'http://push2.eastmoney.com/api/qt/clist/get'
    '?pn=1&pz=25&po=1&np=1&fltt=2&invt=2&fid=f3'
    '&fs=m:0+t:6,m:0+t:80,m:1+t:2'
    '&fields=f2,f3,f4,f5,f12,f14,f15,f16,f17',
  );

  // ---- sector mapping (by prefix ranges) -----------------------------------

  /// Maps A-share codes to sector labels for category chip filtering.
  static String sectorForCode(String code) {
    if (code.startsWith('600') || code.startsWith('601') || code.startsWith('603')) {
      // Shanghai main board — use leading digits to guess sector.
      if (code.startsWith('6019') || code.startsWith('6000')) return '金融';
      if (code.startsWith('6005') || code.startsWith('603')) return '科技';
      if (code.startsWith('6002') || code.startsWith('6007')) return '医药';
      if (code.startsWith('6005') && code[4] == '1') return '消费';
      if (code.startsWith('6018')) return '能源';
      if (code.startsWith('6013')) return '金融';
      return '综合';
    }
    if (code.startsWith('000') || code.startsWith('001') || code.startsWith('002')) {
      // Shenzhen main + SME.
      if (code.startsWith('0008') || code.startsWith('0027')) return '金融';
      if (code.startsWith('0024') || code.startsWith('0020')) return '科技';
      if (code.startsWith('0005') || code.startsWith('0020')) return '医药';
      if (code.startsWith('0008') && code[3] == '5') return '消费';
      if (code.startsWith('0009')) return '能源';
      return '综合';
    }
    if (code.startsWith('300') || code.startsWith('688')) {
      // ChiNext / STAR.
      if (code.startsWith('688')) return '科技';
      if (code.startsWith('3007') || code.startsWith('3005')) return '科技';
      if (code.startsWith('3000') || code.startsWith('3002')) return '医药';
      if (code.startsWith('3004') || code.startsWith('3006')) return '金融';
      return '科技';
    }
    return '综合';
  }

  // ---- fetchAndParse -------------------------------------------------------

  @override
  Future<ParsedMarkets> fetchAndParse() async {
    final response = await client.get(_aShareUri).timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw MarketsFetchException(
        'East Money HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'error'}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected East Money response shape');
    }

    return UsStockService.parseEastMoney(decoded, MarketType.aShare);
  }
}
