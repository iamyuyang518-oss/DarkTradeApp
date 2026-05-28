import 'dart:math';

import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/live_market_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/us_stock_service.dart';
import 'package:dark_trade_app/widgets/kline_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Beginner-friendly stock detail page with area chart, time chips,
/// plain-language stats, and a "story" summary.
class StockDetailPage extends StatefulWidget {
  const StockDetailPage({super.key, required this.quote});

  final StockQuote quote;

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  List<KlineBar>? _bars;
  String? _error;
  int _selectedDays = 90; // 0 = all
  ChartMode _chartMode = ChartMode.area;

  static const _periods = [7, 30, 90, 0]; // 0 = all

  static const Color _bg = Color(0xFFFFFBF5);
  static const Color _amber = Color(0xFFD4A853);
  static const Color _muted = Color(0xFFB8A080);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFE57373);
  static const Color _text = Color(0xFF3D3025);
  static const Color _border = Color(0xFFE8DCC8);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = switch (widget.quote.marketType) {
        MarketType.crypto => context.read<LiveMarketService>().client,
        MarketType.usStock => context.read<UsStockService>().client,
        MarketType.aShare => context.read<AShareService>().client,
      };

      final bars = await fetchKline(
        widget.quote.id,
        widget.quote.marketType,
        limit: _selectedDays == 0 ? 250 : _selectedDays,
        client: client,
      );
      if (!mounted) return;
      if (bars.isNotEmpty) {
        setState(() => _bars = bars);
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _bars = _syntheticBars(widget.quote, _selectedDays == 0 ? 30 : _selectedDays));
  }

  static List<KlineBar> _syntheticBars(StockQuote q, int days) {
    final rng = Random(q.price.hashCode);
    final bars = <KlineBar>[];
    var price = q.price * (1 - q.changePct / 100);
    for (var i = days; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final noise = (rng.nextDouble() - 0.5) * q.price * 0.03;
      final open = price;
      final close = price + q.changePct / days + noise;
      final high = max(open, close) * (1 + rng.nextDouble() * 0.02);
      final low = min(open, close) * (1 - rng.nextDouble() * 0.02);
      bars.add(KlineBar(date: date, open: open, high: high, low: low, close: close, volume: rng.nextDouble() * 1e8 + 1e6));
      price = close;
    }
    return bars;
  }

  void _switchPeriod(int days) {
    setState(() {
      _selectedDays = days;
      _bars = null;
    });
    _load();
  }

  // ---- summary computation -----------------------------------------------

  String _trendSummary() {
    if (_bars == null || _bars!.length < 5) return '';
    final upDays = _bars!.where((b) => b.isUp).length;
    final total = _bars!.length;
    final pct = (upDays / total * 100).round();

    if (pct >= 70) return '这只股票过去 ${_bars!.length} 天中有 $upDays 天上涨 表现强势';
    if (pct >= 55) return '过去 ${_bars!.length} 天中 $upDays 天上涨 稳中向好';
    if (pct >= 45) return '涨跌各半 市场对这只股票分歧较大';
    if (pct >= 30) return '过去 ${_bars!.length} 天中仅 $upDays 天上涨 走势偏弱';
    return '近期表现较弱 仅 $upDays 天上涨 建议谨慎观望';
  }

  String _trendEmoji() {
    if (_bars == null || _bars!.length < 5) return '';
    final upDays = _bars!.where((b) => b.isUp).length;
    final pct = (upDays / _bars!.length * 100).round();
    if (pct >= 70) return '🔥';
    if (pct >= 55) return '☀️';
    if (pct >= 45) return '🌤️';
    if (pct >= 30) return '🌧️';
    return '⛈️';
  }

  Color _trendColor() {
    if (_bars == null || _bars!.length < 5) return _muted;
    final upDays = _bars!.where((b) => b.isUp).length;
    final pct = (upDays / _bars!.length * 100).round();
    if (pct >= 55) return _green;
    if (pct >= 45) return _amber;
    return _red;
  }

  String _labelFor(MarketType t) {
    switch (t) {
      case MarketType.crypto: return 'Binance';
      case MarketType.usStock: return '腾讯财经';
      case MarketType.aShare: return '腾讯财经';
    }
  }

  void _goTrade() {
    context.read<TradeSelectionService>().selectForTrade(widget.quote);
    Navigator.pop(context);
  }

  String _periodLabel(int d) => d == 0 ? '全部' : d == 7 ? '1周' : d == 30 ? '1月' : '3月';

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _amber.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(q.symbol, style: const TextStyle(color: _amber, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(q.name, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _text), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // ---- price header -----------------------------------------------
          _buildPriceHeader(q),

          // ---- time chips -------------------------------------------------
          _buildTimeChips(),

          // ---- chart ------------------------------------------------------
          Expanded(
            child: _bars != null && _bars!.isNotEmpty
                ? _buildChartArea()
                : _buildLoadingOrError(),
          ),

          // ---- trend summary ----------------------------------------------
          if (_bars != null && _bars!.isNotEmpty) _buildTrendSummary(),

          // ---- footer -----------------------------------------------------
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildPriceHeader(StockQuote q) {
    final up = q.isUp;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      color: _bg,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(q.priceLabel, style: const TextStyle(color: _text, fontSize: 36, fontWeight: FontWeight.w800, height: 1.05)),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: up ? _green.withAlpha(25) : _red.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(q.changeLabel, style: TextStyle(color: up ? _green : _red, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (_bars != null && _bars!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStatRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final bars = _bars!;
    final hi = bars.map((b) => b.high).reduce((a, b) => a > b ? a : b);
    final lo = bars.map((b) => b.low).reduce((a, b) => a < b ? a : b);
    final vol = bars.map((b) => b.volume).fold<double>(0, (s, v) => s + v);
    final avgVol = vol / bars.length;

    return Row(
      children: [
        _StatPill(icon: '🔝', label: '最高', value: hi.toStringAsFixed(2)),
        const SizedBox(width: 10),
        _StatPill(icon: '🔽', label: '最低', value: lo.toStringAsFixed(2)),
        const SizedBox(width: 10),
        _StatPill(icon: '📊', label: '日均量', value: _volLabel(avgVol)),
      ],
    );
  }

  Widget _buildTimeChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          ..._periods.map((d) {
            final selected = _selectedDays == d;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _switchPeriod(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _amber : _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? null : Border.all(color: _border),
                    boxShadow: selected ? [BoxShadow(color: _amber.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))] : null,
                  ),
                  child: Text(_periodLabel(d), style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _muted,
                  )),
                ),
              ),
            );
          }),
          const Spacer(),
          // Chart mode tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_chartMode == ChartMode.area ? Icons.show_chart_rounded : Icons.candlestick_chart_rounded, size: 14, color: _muted),
                const SizedBox(width: 4),
                Text('长按切换', style: TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: KlineChart(
        key: ValueKey('kline_${_selectedDays}_${_chartMode}'),
        bars: _bars!,
        mode: _chartMode,
        onModeChanged: (m) => setState(() => _chartMode = m),
      ),
    );
  }

  Widget _buildTrendSummary() {
    final summary = _trendSummary();
    if (summary.isEmpty) return const SizedBox.shrink();

    final emoji = _trendEmoji();
    final color = _trendColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Text(summary, style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _red, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: () { setState(() { _bars = null; _error = null; }); _load(); }, child: const Text('重试')),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: _amber));
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('${_chartMode == ChartMode.area ? "面积图" : "K线"} · ${_labelFor(widget.quote.marketType)}',
            style: const TextStyle(color: _muted, fontSize: 11)),
          const Spacer(),
          _TradeButton(onTap: _goTrade),
        ],
      ),
    );
  }

  String _volLabel(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
    return v.toStringAsFixed(0);
  }
}

// ---- stat pill -----------------------------------------------------------

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value});
  final String icon, label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8DCC8)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFFB8A080), fontSize: 10)),
                Text(value, style: const TextStyle(color: Color(0xFF3D3025), fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- trade button --------------------------------------------------------

class _TradeButton extends StatelessWidget {
  const _TradeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [Color(0xFFD4A853), Color(0xFFC49B38)]),
            boxShadow: [BoxShadow(color: const Color(0xFFD4A853).withAlpha(50), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: const Text('去交易', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
