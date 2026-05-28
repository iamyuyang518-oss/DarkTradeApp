import 'package:dark_trade_app/app/main_tabs_page.dart';
import 'package:dark_trade_app/core/theme.dart';
import 'package:flutter/material.dart';

class DarkTradeApp extends StatelessWidget {
  const DarkTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarkTrade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const MainTabsPage(),
    );
  }
}
