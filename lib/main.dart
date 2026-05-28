import 'package:dark_trade_app/app/main_tabs_page.dart';
import 'package:dark_trade_app/services/a_share_service.dart';
import 'package:dark_trade_app/services/live_market_service.dart';
import 'package:dark_trade_app/services/portfolio_service.dart';
import 'package:dark_trade_app/services/trade_selection_service.dart';
import 'package:dark_trade_app/services/us_stock_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final crypto = LiveMarketService()..start();
  final usStock = UsStockService()..start();
  final aShare = AShareService()..start();
  final portfolio = PortfolioService()..seedDemo();
  final tradeSelection = TradeSelectionService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: crypto),
        ChangeNotifierProvider.value(value: usStock),
        ChangeNotifierProvider.value(value: aShare),
        ChangeNotifierProvider.value(value: portfolio),
        ChangeNotifierProvider.value(value: tradeSelection),
      ],
      child: const DarkTradeApp(),
    ),
  );
}

class DarkTradeApp extends StatelessWidget {
  const DarkTradeApp({super.key});

  static const Color _bg = MainTabsPage.background;
  static const Color _gold = MainTabsPage.selectedGold;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: _gold,
        onPrimary: _bg,
        secondary: _gold,
        onSecondary: _bg,
        surface: Color(0xFF151515),
        onSurface: Color(0xFFE8E8E8),
        error: Color(0xFFCF6679),
        onError: _bg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: Color(0xFFE8E8E8),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _bg,
        selectedItemColor: _gold,
        unselectedItemColor: MainTabsPage.unselectedGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );

    return MaterialApp(
      title: 'Dark Trade',
      debugShowCheckedModeBanner: false,
      theme: dark,
      themeMode: ThemeMode.dark,
      home: const MainTabsPage(),
    );
  }
}
