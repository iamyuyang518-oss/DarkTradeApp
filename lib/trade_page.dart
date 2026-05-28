import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/live_market_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/us_stock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// 黑金风专业交易下单：交易对选择、买卖切换、价格/数量、快捷比例、立即执行。
class TradePage extends StatefulWidget {
  const TradePage({super.key});

  static const Color bg = Color(0xFF0D0D0D);
  static const Color gold = Color(0xFFFFD700);
  static const Color white = Color(0xFFF5F5F5);
  static const Color muted = Color(0xFF8A8A8A);
  static const Color buyGreen = Color(0xFF22C55E);
  static const Color sellRed = Color(0xFFEF4444);
  static const Color toggleIdle = Color(0xFF1E1E1E);
  static const Color toggleIdleText = Color(0xFF6B6B6B);

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> {
  bool _isBuy = true;
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String? _activeStockId;

  void _onFieldsChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _priceCtrl.addListener(_onFieldsChanged);
    _qtyCtrl.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _priceCtrl.removeListener(_onFieldsChanged);
    _qtyCtrl.removeListener(_onFieldsChanged);
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ---- helpers -----------------------------------------------------------

  StockQuote? _findLiveQuote(MarketDataService svc, String id) {
    try {
      return svc.quotes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  StockQuote? _lookupLive(String stockId, MarketType type) {
    final crypto = context.read<LiveMarketService>();
    final usStock = context.read<UsStockService>();
    final aShare = context.read<AShareService>();
    switch (type) {
      case MarketType.crypto:
        return _findLiveQuote(crypto, stockId);
      case MarketType.usStock:
        return _findLiveQuote(usStock, stockId);
      case MarketType.aShare:
        return _findLiveQuote(aShare, stockId);
    }
  }

  double _safeParse(String raw) {
    final s = raw.replaceAll(',', '');
    return double.tryParse(s) ?? 0;
  }

  // ---- trade execution ---------------------------------------------------

  void _applyQuickPercent(double fraction) {
    final portfolio = context.read<PortfolioService>();
    final quote = context.read<TradeSelectionService>().selectedQuote;
    if (quote == null) return;

    HapticFeedback.lightImpact();

    final price = _safeParse(_priceCtrl.text);
    if (price <= 0) return;

    double maxQty;
    if (_isBuy) {
      maxQty = portfolio.usdtBalance / price;
    } else {
      final holding = portfolio.getHolding(quote.id);
      maxQty = holding?.amount ?? 0;
    }

    final qty = maxQty * fraction;
    final s = qty >= 1 ? qty.toStringAsFixed(4) : qty.toStringAsFixed(6);
    setState(() => _qtyCtrl.text = s);
  }

  Future<void> _onExecute() async {
    final price = _safeParse(_priceCtrl.text);
    final qty = _safeParse(_qtyCtrl.text);

    if (price <= 0 || qty <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    final quote = context.read<TradeSelectionService>().selectedQuote;
    if (quote == null) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择交易对')),
      );
      return;
    }

    final portfolio = context.read<PortfolioService>();

    // Validate
    if (_isBuy) {
      if (price * qty > portfolio.usdtBalance + 1e-8) {
        HapticFeedback.heavyImpact();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('USDT 余额不足')),
        );
        return;
      }
    } else {
      final holding = portfolio.getHolding(quote.id);
      if (holding == null || qty > holding.amount + 1e-8) {
        HapticFeedback.heavyImpact();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('持仓不足')),
        );
        return;
      }
    }

    // Execute
    HapticFeedback.mediumImpact();
    if (_isBuy) {
      portfolio.buy(
        stockId: quote.id,
        symbol: quote.symbol,
        name: quote.name,
        marketType: quote.marketType,
        amount: qty,
        price: price,
      );
    } else {
      portfolio.sell(
        stockId: quote.id,
        amount: qty,
        price: price,
      );
    }

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
            side: BorderSide(color: TradePage.gold.withValues(alpha: 0.45)),
          ),
          content: Row(
            children: [
              Icon(Icons.task_alt_rounded, color: TradePage.gold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_isBuy ? "买入" : "卖出"} ${quote.symbol} ${qty.toStringAsFixed(4)}',
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

    _qtyCtrl.clear();
    setState(() {});
  }

  // ---- symbol picker -----------------------------------------------------

  void _openSymbolPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFFFFD700), width: 0.5),
      ),
      builder: (ctx) => _SymbolPickerSheet(),
    );
  }

  // ---- build -------------------------------------------------------------

  OutlineInputBorder _fieldBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: TradePage.gold.withValues(alpha: focused ? 0.55 : 0.28),
        width: focused ? 1.4 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<TradeSelectionService>();
    final quote = selection.selectedQuote;

    // Auto-fill price from live data when symbol changes
    if (quote != null && quote.id != _activeStockId) {
      _activeStockId = quote.id;
      final live = _lookupLive(quote.id, quote.marketType);
      _priceCtrl.text = (live?.price ?? quote.price).toStringAsFixed(2);
    }

    return ColoredBox(
      color: TradePage.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- symbol selector ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SymbolBar(
                quote: quote,
                onTap: _openSymbolPicker,
              ),
            ),
            // ---- buy/sell toggle ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SideToggle(
                isBuy: _isBuy,
                onChanged: (buy) => setState(() => _isBuy = buy),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LabeledField(
                      label: '价格',
                      hint: 'USDT',
                      controller: _priceCtrl,
                      accentGold: true,
                      borderBuilder: _fieldBorder,
                    ),
                    const SizedBox(height: 20),
                    _LabeledField(
                      label: '数量',
                      hint: _isBuy ? '买入数量' : '卖出数量',
                      controller: _qtyCtrl,
                      accentGold: false,
                      borderBuilder: _fieldBorder,
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
                    Row(
                      children: [
                        _QuickChip(
                          label: '25%',
                          onTap: () => _applyQuickPercent(0.25),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          label: '50%',
                          onTap: () => _applyQuickPercent(0.50),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          label: '75%',
                          onTap: () => _applyQuickPercent(0.75),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          label: '100%',
                          onTap: () => _applyQuickPercent(1.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _EstimateRow(
                      isBuy: _isBuy,
                      priceText: _priceCtrl.text,
                      qtyText: _qtyCtrl.text,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _ExecuteButton(isBuy: _isBuy, onPressed: _onExecute),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Symbol selector bar
// ---------------------------------------------------------------------------

class _SymbolBar extends StatelessWidget {
  const _SymbolBar({required this.quote, required this.onTap});

  final StockQuote? quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: TradePage.gold.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              if (quote != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TradePage.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quote!.symbol,
                    style: const TextStyle(
                      color: TradePage.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote!.name,
                    style: const TextStyle(
                      color: TradePage.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  quote!.priceLabel,
                  style: TextStyle(
                    color: quote!.isUp
                        ? TradePage.buyGreen
                        : TradePage.sellRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const Icon(Icons.search, color: TradePage.muted, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '选择交易对',
                    style: TextStyle(
                      color: TradePage.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: TradePage.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Symbol picker bottom sheet
// ---------------------------------------------------------------------------

class _SymbolPickerSheet extends StatefulWidget {
  @override
  State<_SymbolPickerSheet> createState() => _SymbolPickerSheetState();
}

class _SymbolPickerSheetState extends State<_SymbolPickerSheet> {
  String _query = '';

  List<StockQuote> _allQuotes(BuildContext context) {
    final crypto = context.read<LiveMarketService>().quotes;
    final usStock = context.read<UsStockService>().quotes;
    final aShare = context.read<AShareService>().quotes;
    return [...crypto, ...usStock, ...aShare];
  }

  @override
  Widget build(BuildContext context) {
    final all = _allQuotes(context);
    final filtered = _query.isEmpty
        ? all
        : all
            .where((q) =>
                q.symbol.toLowerCase().contains(_query.toLowerCase()) ||
                q.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TradePage.gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              style: const TextStyle(
                color: TradePage.white,
                fontSize: 15,
              ),
              cursorColor: TradePage.gold,
              decoration: InputDecoration(
                hintText: '搜索交易对...',
                hintStyle: const TextStyle(
                  color: TradePage.muted,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.search,
                    color: TradePage.muted, size: 22),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: TradePage.gold.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: TradePage.gold.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: TradePage.gold.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      '无匹配结果',
                      style: TextStyle(color: TradePage.muted, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: TradePage.gold.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (ctx, i) {
                      final q = filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          q.symbol,
                          style: const TextStyle(
                            color: TradePage.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          q.name,
                          style: const TextStyle(
                            color: TradePage.muted,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          q.priceLabel,
                          style: TextStyle(
                            color: q.isUp
                                ? TradePage.buyGreen
                                : TradePage.sellRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          context
                              .read<TradeSelectionService>()
                              .selectForTrade(q);
                          context
                              .read<TradeSelectionService>()
                              .clearNavigation();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable UI widgets (unchanged from original)
// ---------------------------------------------------------------------------

class _SideToggle extends StatelessWidget {
  const _SideToggle({required this.isBuy, required this.onChanged});

  final bool isBuy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: TradePage.toggleIdle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradePage.gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleCell(
              label: '买入',
              selected: isBuy,
              selectedColor: TradePage.buyGreen,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleCell(
              label: '卖出',
              selected: !isBuy,
              selectedColor: TradePage.sellRed,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCell extends StatelessWidget {
  const _ToggleCell({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        splashColor: selectedColor.withValues(alpha: 0.25),
        highlightColor: selectedColor.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? selectedColor : TradePage.toggleIdle,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : TradePage.toggleIdleText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.accentGold,
    required this.borderBuilder,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool accentGold;
  final OutlineInputBorder Function({bool focused}) borderBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: accentGold
                    ? TradePage.gold
                    : TradePage.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              hint,
              style: const TextStyle(
                color: TradePage.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]')),
          ],
          style: const TextStyle(
            color: TradePage.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          cursorColor: TradePage.gold,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: TradePage.bg,
            hintText: '0.00',
            hintStyle: TextStyle(
              color: TradePage.muted.withValues(alpha: 0.45),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: borderBuilder(focused: false),
            focusedBorder: borderBuilder(focused: true),
            border: borderBuilder(focused: false),
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatefulWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _c.forward(from: 0);
    await _c.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.94).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        ),
        child: Material(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _tap,
            borderRadius: BorderRadius.circular(8),
            splashColor: TradePage.gold.withValues(alpha: 0.18),
            highlightColor: TradePage.gold.withValues(alpha: 0.08),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: TradePage.gold.withValues(alpha: 0.22)),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: TradePage.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({
    required this.isBuy,
    required this.priceText,
    required this.qtyText,
  });

  final bool isBuy;
  final String priceText;
  final String qtyText;

  double? _parse(String raw) {
    final s = raw.replaceAll(',', '');
    return double.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    final p = _parse(priceText);
    final q = _parse(qtyText);
    final est = (p != null && q != null) ? (p * q) : null;
    final label = isBuy ? '预估成交额' : '预估卖出额';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TradePage.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: TradePage.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (est != null)
            Text(
              '≈ ${est.toStringAsFixed(2)} USDT',
              style: const TextStyle(
                color: TradePage.gold,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                color: TradePage.muted.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExecuteButton extends StatelessWidget {
  const _ExecuteButton({required this.isBuy, required this.onPressed});

  final bool isBuy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = isBuy ? TradePage.buyGreen : TradePage.sellRed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.12),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                TradePage.gold,
                TradePage.gold.withValues(alpha: 0.82),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '立即执行',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
