import 'dart:math';

import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:flutter/material.dart';

/// Chart display mode.
enum ChartMode { area, candlestick }

/// Dual-mode K-line chart: area chart for beginners, candlestick for advanced.
class KlineChart extends StatefulWidget {
  const KlineChart({
    super.key,
    required this.bars,
    this.height = 340,
    this.mode = ChartMode.area,
    this.onModeChanged,
  });

  final List<KlineBar> bars;
  final double height;
  final ChartMode mode;
  final ValueChanged<ChartMode>? onModeChanged;

  @override
  State<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends State<KlineChart> {
  late ChartMode _mode;
  Offset? _pointerPos;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  @override
  void didUpdateWidget(KlineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) _mode = widget.mode;
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == ChartMode.area ? ChartMode.candlestick : ChartMode.area;
    });
    widget.onModeChanged?.call(_mode);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          _pointerPos = d.localPosition;
          _hoveredIndex = _barIndexAtX(d.localPosition.dx);
        }),
        onPanEnd: (_) => setState(() {
          _pointerPos = null;
          _hoveredIndex = null;
        }),
        onLongPress: _toggleMode,
        child: CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _KlineMultiPainter(
            bars: widget.bars,
            mode: _mode,
            hoveredIndex: _hoveredIndex,
            pointerPos: _pointerPos,
          ),
        ),
      ),
    );
  }

  int _barIndexAtX(double x) {
    final n = widget.bars.length;
    if (n == 0) return 0;
    // Rough: GestureDetector uses full widget width, chart uses ~85% for bars.
    // Just compute proportionally.
    final idx = (x / widget.bars.length).floor();
    return idx.clamp(0, n - 1);
  }
}

// ---- constants -----------------------------------------------------------

const _bg = Color(0xFFFFFBF5);
const _gridColor = Color(0xFFF0E8D8);
const _textColor = Color(0xFFB8A080);
const _upColor = Color(0xFF43A047);
const _downColor = Color(0xFFE57373);
const _upBg = Color(0xFFE8F5E9);
const _downBg = Color(0xFFFFF0F0);
const _amber = Color(0xFFD4A853);
const _crosshairColor = Color(0xFF3D3025);

// ---- painter -------------------------------------------------------------

class _KlineMultiPainter extends CustomPainter {
  _KlineMultiPainter({
    required this.bars,
    required this.mode,
    this.hoveredIndex,
    this.pointerPos,
  });

  final List<KlineBar> bars;
  final ChartMode mode;
  final int? hoveredIndex;
  final Offset? pointerPos;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final priceAxisW = 56.0;
    final bottomH = 36.0;
    final volH = 48.0;
    final topPad = 16.0;
    final chartW = size.width - priceAxisW;
    final mainChartH = size.height - bottomH - volH - topPad - 12;

    // Value range
    double minV = double.infinity, maxV = double.negativeInfinity, maxVol = 0;
    for (final b in bars) {
      if (b.low < minV) minV = b.low;
      if (b.high > maxV) maxV = b.high;
      if (b.volume > maxVol) maxVol = b.volume;
    }
    final span = (maxV - minV) < 1e-6 ? 1.0 : (maxV - minV);

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = _bg);

    // Price grid + labels
    const gridLevels = 5;
    final gridPaint = Paint()..color = _gridColor..strokeWidth = 0.5;
    final labelStyle = TextStyle(color: _textColor, fontSize: 10);

    for (var i = 0; i <= gridLevels; i++) {
      final y = topPad + mainChartH * i / gridLevels;
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
      final price = maxV - span * i / gridLevels;
      final tp = TextPainter(text: TextSpan(text: _fmtPrice(price), style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(chartW + 4, y - tp.height / 2));
    }

    // Volume separator
    final volTop = topPad + mainChartH + 6;
    canvas.drawLine(Offset(0, volTop), Offset(chartW, volTop), gridPaint);

    // Draw chart
    if (mode == ChartMode.area) {
      _drawAreaChart(canvas, size, chartW, mainChartH, topPad, minV, span, maxVol, volH, volTop);
    } else {
      _drawCandlestickChart(canvas, size, chartW, mainChartH, topPad, minV, span, maxVol, volH, volTop);
    }

    // Date labels
    final n = bars.length;
    final dateInterval = max(1, n ~/ 4);
    for (var i = 0; i < n; i += dateInterval) {
      final x = i * (chartW / n) + (chartW / n) / 2;
      final tp = TextPainter(text: TextSpan(text: _fmtDate(bars[i].date), style: labelStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomH + 10));
    }

    // Crosshair
    if (hoveredIndex != null && hoveredIndex! < bars.length && pointerPos != null) {
      _drawCrosshair(canvas, size, chartW, mainChartH, topPad, minV, span);
    }
  }

  void _drawAreaChart(Canvas canvas, Size size, double chartW, double chartH,
      double topPad, double minV, double span, double maxVol, double volH, double volTop) {
    final n = bars.length;
    final stepX = chartW / n;

    // --- Area fill ---
    final isOverallUp = bars.last.close >= bars.first.close;
    final areaColor = isOverallUp ? _upBg : _downBg;

    final areaPath = Path();
    areaPath.moveTo(0, topPad + chartH);
    for (var i = 0; i < n; i++) {
      final x = i * stepX + stepX / 2;
      final y = topPad + chartH - ((bars[i].close - minV) / span) * chartH;
      if (i == 0) areaPath.moveTo(x, topPad + chartH);
      areaPath.lineTo(x, y);
    }
    areaPath.lineTo((n - 1) * stepX + stepX / 2, topPad + chartH);
    areaPath.close();

    canvas.drawPath(areaPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [areaColor.withAlpha(180), areaColor.withAlpha(20)],
      ).createShader(Rect.fromLTWH(0, topPad, chartW, chartH)));

    // --- Line ---
    final lineColor = isOverallUp ? _upColor : _downColor;
    final linePath = Path();
    for (var i = 0; i < n; i++) {
      final x = i * stepX + stepX / 2;
      final y = topPad + chartH - ((bars[i].close - minV) / span) * chartH;
      if (i == 0) { linePath.moveTo(x, y); } else { linePath.lineTo(x, y); }
    }
    canvas.drawPath(linePath, Paint()
      ..color = lineColor..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // --- Latest price dot ---
    final lastX = (n - 1) * stepX + stepX / 2;
    final lastY = topPad + chartH - ((bars.last.close - minV) / span) * chartH;
    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = lineColor);
    canvas.drawCircle(Offset(lastX, lastY), 9, Paint()..color = lineColor.withAlpha(40));

    // --- Volume bars ---
    _drawVolumeBars(canvas, n, stepX, chartW, volTop, volH, maxVol, isOverallUp);
  }

  void _drawCandlestickChart(Canvas canvas, Size size, double chartW, double chartH,
      double topPad, double minV, double span, double maxVol, double volH, double volTop) {
    final n = bars.length;
    final candleW = (chartW / n) * 0.65;
    final halfGap = (chartW / n - candleW) / 2;

    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final wickPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;

    for (var i = 0; i < n; i++) {
      final b = bars[i];
      final x = i * (chartW / n) + halfGap + candleW / 2;
      final yOpen = topPad + chartH - ((b.open - minV) / span) * chartH;
      final yClose = topPad + chartH - ((b.close - minV) / span) * chartH;
      final yHigh = topPad + chartH - ((b.high - minV) / span) * chartH;
      final yLow = topPad + chartH - ((b.low - minV) / span) * chartH;
      final color = b.isUp ? _upColor : _downColor;

      wickPaint.color = color;
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      final bodyTop = b.isUp ? yClose : yOpen;
      final bodyBot = b.isUp ? yOpen : yClose;
      final bodyH = max(1.0, (bodyBot - bodyTop).abs());
      bodyPaint.color = color;
      canvas.drawRect(Rect.fromCenter(center: Offset(x, (bodyTop + bodyBot) / 2), width: candleW, height: bodyH), bodyPaint);
    }

    // MA lines
    _drawMA(canvas, bars, chartW, n, chartH, topPad, minV, span, 5, const Color(0xFFE8B84B));
    _drawMA(canvas, bars, chartW, n, chartH, topPad, minV, span, 10, const Color(0xFF8B9DC3));

    // Volume
    final stepX = chartW / n;
    _drawVolumeBars(canvas, n, stepX, chartW, volTop, volH, maxVol, true);
  }

  void _drawVolumeBars(Canvas canvas, int n, double stepX, double chartW,
      double volTop, double volH, double maxVol, bool isOverallUp) {
    if (maxVol <= 0) return;
    final barW = max(1.5, stepX * 0.6);
    for (var i = 0; i < n; i++) {
      final b = bars[i];
      final x = i * stepX + stepX / 2;
      final h = (b.volume / maxVol) * volH;
      final color = b.isUp ? _upColor.withAlpha(60) : _downColor.withAlpha(60);
      canvas.drawRect(Rect.fromLTWH(x - barW / 2, volTop + volH - max(1.0, h), barW, max(1.0, h)), Paint()..color = color);
    }
  }

  void _drawMA(Canvas canvas, List<KlineBar> b, double chartW, int n, double chartH,
      double topPad, double minV, double span, int period, Color color) {
    if (n < period) return;
    final stepX = chartW / n;
    final paint = Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    var started = false;
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += b[i].close;
      if (i >= period) sum -= b[i - period].close;
      if (i >= period - 1) {
        final x = i * stepX + stepX / 2;
        final y = topPad + chartH - ((sum / period - minV) / span) * chartH;
        if (!started) { path.moveTo(x, y); started = true; } else { path.lineTo(x, y); }
      }
    }
    if (started) canvas.drawPath(path, paint);
  }

  void _drawCrosshair(Canvas canvas, Size size, double chartW, double chartH,
      double topPad, double minV, double span) {
    final i = hoveredIndex!;
    final b = bars[i];
    final stepX = chartW / bars.length;
    final x = i * stepX + stepX / 2;
    final y = topPad + chartH - ((b.close - minV) / span) * chartH;

    final crossPaint = Paint()..color = _crosshairColor.withAlpha(30)..strokeWidth = 0.8;
    canvas.drawLine(Offset(x, topPad), Offset(x, topPad + chartH), crossPaint);
    canvas.drawLine(Offset(0, y), Offset(chartW, y), crossPaint);

    // Price tag
    final tagText = _fmtPrice(b.close);
    final tagTp = TextPainter(text: TextSpan(text: tagText, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
    final tagW = tagTp.width + 12, tagH = tagTp.height + 6;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(chartW + 2, y - tagH / 2, tagW, tagH), Radius.circular(4)), Paint()..color = _amber);
    tagTp.paint(canvas, Offset(chartW + 8, y - tagTp.height / 2));
  }

  String _fmtPrice(double p) {
    if (p >= 100000) return '${(p / 10000).toStringAsFixed(1)}万';
    if (p >= 10000) return '${(p / 10000).toStringAsFixed(2)}万';
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    if (p >= 0.01) return p.toStringAsFixed(6);
    return p.toStringAsFixed(8);
  }

  String _fmtDate(DateTime d) => '${d.month}/${d.day}';

  @override
  bool shouldRepaint(covariant _KlineMultiPainter old) =>
      old.bars != bars || old.mode != mode || old.hoveredIndex != hoveredIndex;
}
