import 'package:hive_flutter/hive_flutter.dart';
import 'models/career.dart';
import 'models/trade_record.dart';

class HiveService {
  static const String careersBox = 'careers';
  static const String tradeHistoryBox = 'tradeHistory';
  static const String prefsBox = 'prefs';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CareerAdapter());
    Hive.registerAdapter(TradeRecordAdapter());
    Hive.registerAdapter(TradeTypeAdapter());
    Hive.registerAdapter(MarketTypeAdapter());
    await Future.wait([
      Hive.openBox<Career>(careersBox),
      Hive.openBox<TradeRecord>(tradeHistoryBox),
      Hive.openBox(prefsBox),
    ]);
  }

  static Box<Career> get careers => Hive.box<Career>(careersBox);
  static Box<TradeRecord> get tradeHistory =>
      Hive.box<TradeRecord>(tradeHistoryBox);
  static Box get prefs => Hive.box(prefsBox);
}
