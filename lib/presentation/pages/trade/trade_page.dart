import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/presentation/pages/trade/logic/trade_form_controller.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/estimate_row.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/execute_button.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/labeled_field.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/quick_position_chips.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/side_toggle.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/symbol_bar.dart';
import 'package:dark_trade_app/presentation/pages/trade/widgets/symbol_picker_sheet.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/presentation/widgets/confetti_overlay.dart';
import 'package:dark_trade_app/presentation/widgets/tip_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// 黑金风专业交易下单页 — 编排器。
/// 所有可复用组件已抽离至 [widgets/]，核心逻辑由 [TradeFormController] 管理。
class TradePage extends StatefulWidget {
  const TradePage({super.key});

  static const Color bg = Color(0xFFFFFBF5);
  static const Color gold = Color(0xFFD4A853);
  static const Color white = Color(0xFF3D3025);

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> {
  late final TradeFormController _c;
  bool _showConfetti = false;

  // ---- price lookup helpers ------------------------------------------------

  StockQuote? _findLive(MarketDataService svc, String id) {
    try {
      return svc.quotes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  StockQuote? _lookupLive(String stockId, MarketType type) {
    return _findLive(context.read<AShareService>(), stockId);
  }

  // ---- symbol picker -------------------------------------------------------

  void _openSymbolPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFFD4A853), width: 0.5),
      ),
      builder: (_) => const SymbolPickerSheet(),
    );
  }

  // ---- quick percent -------------------------------------------------------

  void _applyQuickPercent(double fraction) {
    HapticFeedback.lightImpact();
    _c.applyQuickPercent(
      fraction,
      portfolio: context.read<PortfolioService>(),
    );
  }

  // ---- execute -------------------------------------------------------------

  void _onExecute() {
    final result = _c.execute(portfolio: context.read<PortfolioService>());

    if (result.success) {
      HapticFeedback.mediumImpact();
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showConfetti = false);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: const Color(0xFF0A0A0A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: TradePage.gold.withValues(alpha: 0.45)),
            ),
            content: Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    color: TradePage.gold, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.message,
                    style: const TextStyle(
                      color: TradePage.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } else {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  // ---- lifecycle -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _c = TradeFormController(
      careerService: context.read<CareerService>(),
      tradeHistoryService: context.read<TradeHistoryService>(),
    );
    // Sync controller with cross-tab selection changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quote = context.read<TradeSelectionService>().selectedQuote;
      if (quote != null) {
        _c.selectQuote(quote);
        _c.autoFillPrice(_lookupLive);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // React to cross-tab selection changes
    final selection = context.watch<TradeSelectionService>();
    final quote = selection.selectedQuote;
    if (quote != null && _c.selectedQuote?.id != quote.id) {
      _c.selectQuote(quote);
      _c.autoFillPrice(_lookupLive);
    }

    final careerService = context.watch<CareerService>();

    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return ColoredBox(
          color: TradePage.bg,
          child: SafeArea(
            child: ConfettiOverlay(
              play: _showConfetti,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: SymbolBar(
                      quote: _c.selectedQuote,
                      onTap: _openSymbolPicker,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text('可用', style: TextStyle(color: Color(0xFFA09078), fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(
                          '${careerService.activeCareer?.currentBalance.toStringAsFixed(2) ?? "0.00"} USDT',
                          style: const TextStyle(
                            color: Color(0xFFD4A853),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: SideToggle(
                      isBuy: _c.isBuy,
                      onChanged: (buy) => _c.toggleSide(buy),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LabeledField(
                            label: '价格',
                            hint: 'USDT',
                            controller: _c.priceCtrl,
                            accentGold: true,
                          ),
                          const SizedBox(height: 20),
                          LabeledField(
                            label: '数量',
                            hint: _c.isBuy ? '买入数量' : '卖出数量',
                            controller: _c.qtyCtrl,
                            accentGold: false,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            '快捷仓位',
                            style: TextStyle(
                              color: TradePage.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          QuickPositionChips(
                            onPercentTap: _applyQuickPercent,
                          ),
                          const SizedBox(height: 20),
                          EstimateRow(
                            isBuy: _c.isBuy,
                            price: _c.price,
                            quantity: _c.quantity,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TipBubble(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: ExecuteButton(
                      isBuy: _c.isBuy,
                      onPressed: _onExecute,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      AppText.disclaimerFooter,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
