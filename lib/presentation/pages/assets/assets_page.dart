import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/presentation/pages/profile/trade_history_page.dart';
import 'package:dark_trade_app/presentation/widgets/career_selector.dart';
import 'package:dark_trade_app/presentation/widgets/gain_loss_card.dart';
import 'package:dark_trade_app/presentation/widgets/equity_curve_chart.dart';
import 'package:dark_trade_app/presentation/widgets/share_card.dart';
import 'package:dark_trade_app/presentation/widgets/hover_card.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Warm theme asset page: total in RMB, allocation, holdings — with live quotes.
class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  static String _formatRmb(double v) {
    final s = v.toStringAsFixed(2);
    final dot = s.indexOf('.');
    var whole = s.substring(0, dot);
    final frac = s.substring(dot);
    final neg = whole.startsWith('-');
    if (neg) whole = whole.substring(1);
    final buf = StringBuffer();
    if (neg) buf.write('-');
    buf.write('¥');
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
    final auth = context.read<AuthService>();
    final username = auth.username ?? '交易员';

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
        valueRmb: h.amount * livePrice,
      );
    }).toList();

    // Total value = cash balance + all holdings
    final totalValue = portfolio.usdtBalance +
        holdings.fold<double>(0, (s, h) => s + h.valueRmb);

    // Compute today's PnL from holdings * daily price change
    double todayPnl = 0;
    for (final h in portfolio.holdings) {
      final quote = aShare.quotes.cast<StockQuote?>().firstWhere(
        (q) => q?.symbol == h.symbol,
        orElse: () => null,
      );
      if (quote != null) {
        todayPnl += h.amount * (quote.changePct / 100) * quote.price;
      }
    }

    // Allocations: cash + each holding
    final allocations = <_DisplayAllocation>[];
    if (portfolio.usdtBalance > 0) {
      allocations.add(_DisplayAllocation(
        symbol: '现金',
        percent: totalValue > 0 ? portfolio.usdtBalance / totalValue : 0,
      ));
    }
    for (final h in holdings) {
      allocations.add(_DisplayAllocation(
        symbol: h.symbol,
        percent: totalValue > 0 ? h.valueRmb / totalValue : 0,
      ));
    }

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 800;
            if (isWide) {
              return _buildWideLayout(
                ctx, totalValue, todayPnl, activeCareer,
                holdings, allocations, username,
              );
            } else {
              return _buildMobileLayout(
                ctx, totalValue, todayPnl, activeCareer,
                holdings, allocations, username,
              );
            }
          },
        ),
      ),
    );
  }

  void _fillPriceMap(Map<String, double> map, List<StockQuote> quotes) {
    for (final q in quotes) {
      map[q.id] = q.price;
    }
  }

  // ---- wide layout: two-column ----

  Widget _buildWideLayout(
    BuildContext context,
    double totalValue,
    double todayPnl,
    Career? activeCareer,
    List<_DisplayHolding> holdings,
    List<_DisplayAllocation> allocations,
    String username,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Career selector
          if (activeCareer != null)
            const Align(
              alignment: Alignment.centerRight,
              child: CareerSelector(),
            ),
          const SizedBox(height: 24),
          // Main two-column
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Left column (flex: 3) ----
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Greeting + Total assets with gold gradient
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.surface, AppColors.goldBg],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '你好，$username 👋',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '总资产',
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRmb(totalValue),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '估值以人民币计价',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // GainLossCard
                    if (activeCareer != null)
                      GainLossCard(
                        career: activeCareer,
                        todayPnl: todayPnl,
                        upColor: AppColors.up,
                        downColor: AppColors.down,
                      ),
                    const SizedBox(height: 12),
                    // Share button
                    if (activeCareer != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final auth = context.read<AuthService>();
                              final cs = context.read<CareerService>();
                              final ac = cs.activeCareer;
                              if (ac != null) {
                                sharePerformanceCard(context, ac, auth.username ?? '交易员');
                              }
                            },
                            icon: const Icon(Icons.share, color: AppColors.gold),
                            label: const Text('分享战绩', style: TextStyle(color: AppColors.gold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.gold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Holdings header
                    if (holdings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '持仓',
                            style: TextStyle(
                              color: AppColors.textPrimary.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    // Holdings list
                    if (holdings.isNotEmpty)
                      ...holdings.map((h) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _HoldingTile(holding: h),
                      )),
                    // Empty state
                    if (holdings.isEmpty && totalValue <= 0)
                      _buildEmptyState(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // ---- Right column (flex: 2) ----
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Emotion card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildEmotionCard(context),
                    ),
                    const SizedBox(height: 16),
                    // Equity curve
                    if (activeCareer != null)
                      EquityCurveChart(data: activeCareer.equityHistory),
                    const SizedBox(height: 16),
                    // Allocation card
                    if (allocations.isNotEmpty)
                      _buildAllocationCard(allocations),
                    const SizedBox(height: 16),
                    // Trade history button
                    if (activeCareer != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TradeHistoryPage()),
                              );
                            },
                            icon: const Icon(Icons.receipt_long, color: AppColors.background),
                            label: const Text(
                              '交易记录',
                              style: TextStyle(
                                color: AppColors.background,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- mobile layout: existing sliver-based ----

  Widget _buildMobileLayout(
    BuildContext context,
    double totalValue,
    double todayPnl,
    Career? activeCareer,
    List<_DisplayHolding> holdings,
    List<_DisplayAllocation> allocations,
    String username,
  ) {
    return CustomScrollView(
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
                  '你好，$username 👋',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '总资产',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRmb(totalValue),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '估值以人民币计价',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
              todayPnl: todayPnl,
              upColor: AppColors.up,
              downColor: AppColors.down,
            ),
          ),

        // ---- 情绪仪表盘 ----
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _buildEmotionCard(context),
          ),
        ),

        // ---- 战绩分享 ----
        if (activeCareer != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final auth = context.read<AuthService>();
                    final cs = context.read<CareerService>();
                    final ac = cs.activeCareer;
                    if (ac != null) {
                      sharePerformanceCard(context, ac, auth.username ?? '交易员');
                    }
                  },
                  icon: const Icon(Icons.share, color: AppColors.gold),
                  label: const Text('分享战绩', style: TextStyle(color: AppColors.gold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
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
                  icon: const Icon(Icons.receipt_long, color: AppColors.background),
                  label: const Text(
                    '交易记录',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
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
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
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
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
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
        if (holdings.isEmpty && totalValue <= 0)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 56,
                      color: AppColors.unselectedBg),
                  const SizedBox(height: 12),
                  Text(
                    AppText.emptyHoldingsTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.65),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppText.emptyHoldings,
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
    );
  }

  // ---- emotion card ----

  Widget _buildEmotionCard(BuildContext context) {
    return Consumer<TradeHistoryService>(
      builder: (context, tradeHistory, _) {
        final recentTrades = tradeHistory.records
            .where((r) => r.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 7))))
            .length;

        final Color emotionColor;
        final Color emotionBg;
        final String emoji;
        final String label;
        final String hint;

        if (recentTrades <= 1) {
          emotionColor = AppColors.emotionZen;
          emotionBg = AppColors.emotionZenBg;
          emoji = '🧘';
          label = '佛系';
          hint = '淡定持有，心如止水';
        } else if (recentTrades <= 5) {
          emotionColor = AppColors.emotionPopcorn;
          emotionBg = AppColors.emotionPopcornBg;
          emoji = '🍿';
          label = '吃瓜';
          hint = '观望中，吃瓜看戏';
        } else {
          emotionColor = AppColors.emotionFire;
          emotionBg = AppColors.emotionFireBg;
          emoji = '🔥';
          label = '上头';
          hint = '交易频繁，注意休息';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: emotionBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: emotionColor, width: 1.5),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$emoji $label',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- allocation card ----

  Widget _buildAllocationCard(List<_DisplayAllocation> allocations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '资产分布',
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < allocations.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _DistributionTile(allocation: allocations[i]),
          ],
        ],
      ),
    );
  }

  // ---- empty state (non-sliver, for wide layout) ----

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: AppColors.unselectedBg),
            const SizedBox(height: 12),
            Text(
              AppText.emptyHoldingsTitle,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.65),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              AppText.emptyHoldings,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
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
    required this.valueRmb,
  });
  final String symbol;
  final String name;
  final double amount;
  final String unit;
  final double price;
  final double valueRmb;
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
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                color: AppColors.gold,
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
            backgroundColor: AppColors.unselectedBg,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.gold),
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

    return HoverCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              holding.symbol.length >= 3
                  ? holding.symbol.substring(0, 3)
                  : holding.symbol,
              style: const TextStyle(
                color: AppColors.gold,
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
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amountStr ${holding.unit}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AssetsPage._formatRmb(holding.valueRmb),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
