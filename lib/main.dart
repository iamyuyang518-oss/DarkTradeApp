import 'package:dark_trade_app/app/main_tabs_page.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/data/local/hive_service.dart';
import 'package:dark_trade_app/domain/services/live_market_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/us_stock_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  final crypto = LiveMarketService()..start();
  final usStock = UsStockService()..start();
  final aShare = AShareService()..start();
  final portfolio = PortfolioService()..seedDemo();
  final tradeSelection = TradeSelectionService();
  final careerService = CareerService();
  final tradeHistory = TradeHistoryService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: crypto),
        ChangeNotifierProvider.value(value: usStock),
        ChangeNotifierProvider.value(value: aShare),
        ChangeNotifierProvider.value(value: portfolio),
        ChangeNotifierProvider.value(value: tradeSelection),
        ChangeNotifierProvider.value(value: careerService),
        ChangeNotifierProvider.value(value: tradeHistory),
      ],
      child: const DarkTradeApp(),
    ),
  );
}

class DarkTradeApp extends StatelessWidget {
  const DarkTradeApp({super.key});

  static const Color _bg = MainTabsPage.background;
  static const Color _amber = MainTabsPage.selectedGold;

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: _amber,
        onPrimary: Color(0xFFFFFFFF),
        secondary: _amber,
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF3D3025),
        error: Color(0xFFE57373),
        onError: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: Color(0xFF3D3025),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _bg,
        selectedItemColor: _amber,
        unselectedItemColor: MainTabsPage.unselectedGray,
        type: BottomNavigationBarType.fixed,
        elevation: 1,
      ),
    );

    return MaterialApp(
      title: 'Dark Trade',
      debugShowCheckedModeBanner: false,
      theme: light,
      themeMode: ThemeMode.light,
      home: const MainTabsPage(),
    );
  }
}
