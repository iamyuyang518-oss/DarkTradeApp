import 'package:dark_trade_app/assets_page.dart';
import 'package:dark_trade_app/market_explorer.dart';
import 'package:dark_trade_app/profile_page.dart';
import 'package:dark_trade_app/services/trade_selection_service.dart';
import 'package:dark_trade_app/presentation/pages/trade/trade_page.dart';
import 'package:flutter/material.dart';
import '../widgets/guest_banner.dart';
import 'package:provider/provider.dart';

/// Shell: bottom navigation + [IndexedStack] so each tab keeps its own state.
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  static const Color background = Color(0xFF0D0D0D);
  static const Color selectedGold = Color(0xFFFFD700);
  static const Color unselectedGray = Color(0xFF8A8A8A);

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _index = 0;

  /// Built once; [IndexedStack] keeps subtree state when switching tabs.
  late final List<Widget> _pages = <Widget>[
    const MarketExplorerWidget(),
    const AssetsPage(),
    const TradePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<TradeSelectionService>().addListener(_onTradeSelectionChanged);
  }

  @override
  void dispose() {
    context.read<TradeSelectionService>().removeListener(_onTradeSelectionChanged);
    super.dispose();
  }

  void _onTradeSelectionChanged() {
    final svc = context.read<TradeSelectionService>();
    if (svc.shouldNavigateToTrade) {
      svc.clearNavigation();
      setState(() => _index = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MainTabsPage.background,
      body: Column(
        children: [
          const GuestBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: MainTabsPage.selectedGold.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: MainTabsPage.background,
          selectedItemColor: MainTabsPage.selectedGold,
          unselectedItemColor: MainTabsPage.unselectedGray,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: '行情',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: '资产',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: '交易',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '个人',
            ),
          ],
        ),
      ),
    );
  }
}
