import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/presentation/pages/profile/trade_history_page.dart';
import 'package:dark_trade_app/presentation/widgets/career_selector.dart';
import 'package:dark_trade_app/presentation/widgets/gain_loss_card.dart';
import 'package:dark_trade_app/presentation/widgets/equity_curve_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 极简黑金资产页：总折合、分布占比、持仓明细 —— 接入实时行情。
class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  static const Color _bg = Color(0xFFFFFBF5);
  static const Color _gold = Color(0xFFD4A853);
  static const Color _white = Color(0xFF3D3025);
  static const Color _muted = Color(0xFFB8A080);

  static String _formatUsd(double v) {
    final s = v.toStringAsFixed(2);
    final dot = s.indexOf('.');
    var whole = s.substring(0, dot);
    final frac = s.substring(dot);
    final neg = whole.startsWith('-');
    if (neg) whole = whole.substring(1);
    final buf = StringBuffer();
    if (neg) buf.write('-');
    buf.write(r'$');
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    buf.write(frac);
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Watch all data sources for reactive updates
    final aShare = context.watch<AShareService>();
    final portfolio = context.watch<PortfolioService>();
    final careerService = context.watch<CareerService>();
    final activeCareer = careerService.activeCareer;

    // Build price lookup for display
    final priceMap = <String, double>{};
    _fillPriceMap(priceMap, aShare.quotes);

    // Compute holdings with live prices
    final holdings = portfolio.holdings.map((h) {
      final livePrice = priceMap[h.stockId] ?? h.lastKnownPrice;
      return _DisplayHolding(
        symbol: h.symbol,
        name: h.name,
        amount: h.amount,
        unit: h.symbol,
        price: livePrice,
        valueUsd: h.amount * livePrice,
      );
    }).toList();

    // Total value = USDT balance + all holdings
    final totalValue = portfolio.usdtBalance +
        holdings.fold<double>(0, (s, h) => s + h.valueUsd);

    // Allocations: USDT + each holding
    final allocations = <_DisplayAllocation>[];
    if (portfolio.usdtBalance > 0) {
      allocations.add(_DisplayAllocation(
        symbol: 'USDT',
        percent: totalValue > 0 ? portfolio.usdtBalance / totalValue : 0,
      ));
    }
    for (final h in holdings) {
      allocations.add(_DisplayAllocation(
        symbol: h.symbol,
        percent: totalValue > 0 ? h.valueUsd / totalValue : 0,
      ));
    }

    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---- 生涯选择器 ----
            if (activeCareer != null)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CareerSelector(),
                  ),
                ),
              ),

            // ---- 总资产 ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '总资产折合',
                      style: TextStyle(
                        color: _white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatUsd(totalValue),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '估值以 USDT 计价',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- 盈亏卡片 ----
            if (activeCareer != null)
              SliverToBoxAdapter(
                child: GainLossCard(
                  career: activeCareer,
                  todayPnl: 0, // TODO: compute from holdings * daily price change
                ),
              ),

            // ---- 权益曲线 ----
            if (activeCareer != null)
              SliverToBoxAdapter(
                child: EquityCurveChart(data: activeCareer.equityHistory),
              ),

            // ---- 交易记录按钮 ----
            if (activeCareer != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TradeHistoryPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, color: _bg),
                      label: const Text(
                        '交易记录',
                        style: TextStyle(
                          color: _bg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ---- 资产分布 ----
            if (allocations.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    '资产分布',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (allocations.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: allocations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) =>
                      _DistributionTile(allocation: allocations[i]),
                ),
              ),

            // ---- 持仓 ----
            if (holdings.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                  child: Text(
                    '持仓',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (holdings.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: holdings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _HoldingTile(holding: holdings[i]),
                ),
              ),

            // ---- empty state ----
            if (holdings.isEmpty && portfolio.usdtBalance <= 0)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 56,
                          color: _muted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        '暂无持仓',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.65),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '前往交易页开始你的第一笔交易',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _fillPriceMap(Map<String, double> map, List<StockQuote> quotes) {
    for (final q in quotes) {
      map[q.id] = q.price;
    }
  }
}

// ---- display models ----

class _DisplayAllocation {
  const _DisplayAllocation({required this.symbol, required this.percent});
  final String symbol;
  final double percent;
}

class _DisplayHolding {
  const _DisplayHolding({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.unit,
    required this.price,
    required this.valueUsd,
  });
  final String symbol;
  final String name;
  final double amount;
  final String unit;
  final double price;
  final double valueUsd;
}

// ---- tiles ----

class _DistributionTile extends StatelessWidget {
  const _DistributionTile({required this.allocation});
  final _DisplayAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final pct = (allocation.percent * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              allocation.symbol,
              style: const TextStyle(
                color: AssetsPage._white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                color: AssetsPage._gold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: allocation.percent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF5EDE0),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AssetsPage._gold),
          ),
        ),
      ],
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({required this.holding});
  final _DisplayHolding holding;

  @override
  Widget build(BuildContext context) {
    final amountStr = holding.amount >= 1
        ? holding.amount.toStringAsFixed(4)
        : holding.amount.toStringAsFixed(6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AssetsPage._gold.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AssetsPage._gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              holding.symbol.length >= 3
                  ? holding.symbol.substring(0, 3)
                  : holding.symbol,
              style: const TextStyle(
                color: AssetsPage._gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.name,
                  style: const TextStyle(
                    color: AssetsPage._white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amountStr ${holding.unit}',
                  style: const TextStyle(
                    color: AssetsPage._muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AssetsPage._formatUsd(holding.valueUsd),
            style: const TextStyle(
              color: AssetsPage._gold,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
