import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/achievement_service.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';
import 'package:dark_trade_app/presentation/pages/assets/assets_page.dart';
import 'package:dark_trade_app/presentation/pages/market/market_page.dart';
import 'package:dark_trade_app/presentation/pages/profile/profile_page.dart';
import 'package:dark_trade_app/presentation/pages/trade/trade_page.dart';
import 'package:dark_trade_app/presentation/widgets/guest_banner.dart';
import 'package:dark_trade_app/presentation/widgets/onboarding_dialog.dart';
import 'package:dark_trade_app/presentation/widgets/risk_disclaimer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shell: bottom navigation + [IndexedStack] so each tab keeps its own state.
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  static const Color background = Color(0xFFFFFBF5);
  static const Color selectedGold = Color(0xFFD4A853);
  static const Color unselectedGray = Color(0xFFB8A080);

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _index = 0;
  bool _disclaimerShown = false;
  late final TradeSelectionService _tradeSelection;

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
    final auth = context.read<AuthService>();
    final careerService = context.read<CareerService>();
    final tradeHistory = context.read<TradeHistoryService>();
    final watchlistService = context.read<WatchlistService>();
    auth.wireServices(careerService, tradeHistory, watchlistService);
    _tradeSelection = context.read<TradeSelectionService>();
    _tradeSelection.addListener(_onTradeSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  void _checkOnboarding() {
    final careerService = context.read<CareerService>();
    if (careerService.careers.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WelcomeDialog(
          onConfirm: (name, balance) {
            careerService.createCareer(name, balance);
            Navigator.of(context).pop();
            _showTabHint();
            _checkDisclaimer();
          },
        ),
      );
    } else {
      _checkDisclaimer();
    }
  }

  void _checkDisclaimer() {
    if (_disclaimerShown) return;
    _disclaimerShown = true;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RiskDisclaimerDialog(),
    );
  }

  void _showTabHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('👆 从这里探索 A 股市场'),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tradeSelection.removeListener(_onTradeSelectionChanged);
    super.dispose();
  }

  void _onTradeSelectionChanged() {
    final svc = _tradeSelection;
    if (svc.shouldNavigateToTrade) {
      svc.clearNavigation();
      setState(() => _index = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: MainTabsPage.background,
      body: auth.initialized
          ? Column(
              children: [
                const GuestBanner(),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: _pages,
                  ),
                ),
                // Achievement unlock toast
                Consumer<AchievementService>(
                  builder: (context, service, _) {
                    if (service.justUnlocked != null) {
                      final a = service.achievements
                          .firstWhere((a) => a.id == service.justUnlocked);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text('${a.emoji} 成就解锁！',
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold)),
                            content: Text('${a.name}\n${a.description}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  service.clearJustUnlocked();
                                },
                                child: const Text('太棒了！',
                                    style: TextStyle(color: AppColors.gold)),
                              ),
                            ],
                          ),
                        );
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MainTabsPage.selectedGold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在加载...',
                    style: TextStyle(
                        color: MainTabsPage.unselectedGray, fontSize: 14),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: auth.initialized
          ? Theme(
              data: Theme.of(context).copyWith(
                splashColor:
                    MainTabsPage.selectedGold.withValues(alpha: 0.12),
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
                    fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 12),
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.show_chart_outlined),
                      activeIcon: Icon(Icons.show_chart),
                      label: '行情'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      activeIcon: Icon(Icons.account_balance_wallet),
                      label: '资产'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.swap_horiz_outlined),
                      activeIcon: Icon(Icons.swap_horiz),
                      label: '交易'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: '个人'),
                ],
              ),
            )
          : null,
    );
  }
}
