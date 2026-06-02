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
import 'package:dark_trade_app/presentation/widgets/app_shell.dart';
import 'package:dark_trade_app/presentation/widgets/guest_banner.dart';
import 'package:dark_trade_app/presentation/widgets/onboarding_dialog.dart';
import 'package:dark_trade_app/presentation/widgets/risk_disclaimer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Entry shell: responsive sidebar/bottom-nav + onboarding flow.
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  bool _disclaimerShown = false;
  late final TradeSelectionService _tradeSelection;

  late final List<Widget> _pages = const [
    MarketExplorerWidget(),
    AssetsPage(),
    TradePage(),
    ProfilePage(),
  ];

  static const _labels = ['行情', '资产', '交易', '个人'];
  static const _icons = [
    Icons.show_chart_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.swap_horiz_outlined,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.show_chart,
    Icons.account_balance_wallet,
    Icons.swap_horiz,
    Icons.person,
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
    // With AppShell, navigation is internal. The AppShell manages its own index.
    // For now, cross-tab navigation is still handled by TradeSelectionService listener in TradePage.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.initialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '数据正在路上... 🚀',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        AppShell(
          pages: _pages,
          labels: _labels,
          icons: _icons,
          activeIcons: _activeIcons,
        ),
        // Guest banner overlay (only on mobile where there's no sidebar user card)
        if (!auth.isLoggedIn)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GuestBanner(),
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
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    title: Text('${a.emoji} 成就解锁！',
                        style: const TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.bold)),
                    content: Text('${a.name}\n${a.description}',
                        style: const TextStyle(color: AppColors.textPrimary)),
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
    );
  }
}
