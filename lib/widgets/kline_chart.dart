import 'package:dark_trade_app/services/market_data_service.dart';
import 'package:flutter/material.dart';

/// K-line chart widget drawing OHLC candlesticks.
class KlineChart extends StatelessWidget {
  const KlineChart({
    super.key,
    required this.bars,
    this.height = 260,
  });

  final List<KlineBar> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _KlinePainter(bars: bars),
      ),
    );
  }
}

class _KlinePainter extends CustomPainter {
  _KlinePainter({required this.bars});

  final List<KlineBar> bars;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final n = bars.length;
    final candleW = (size.width / n) * 0.65;
    final gap = (size.width / n) * 0.35;

    // Value range
    double minV = double.infinity;
    double maxV = double.negativeInfinity;
    for (final b in bars) {
      if (b.low < minV) minV = b.low;
      if (b.high > maxV) maxV = b.high;
    }
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final topPad = 8.0;
    final bottomPad = 8.0;
    final chartH = size.height - topPad - bottomPad;

    final candlePaint = Paint()..style = PaintingStyle.fill;
    final wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < n; i++) {
      final b = bars[i];
      final x = i * (size.width / n) + gap / 2 + candleW / 2;

      final yOpen =
          topPad + chartH - ((b.open - minV) / span) * chartH;
      final yClose =
          topPad + chartH - ((b.close - minV) / span) * chartH;
      final yHigh =
          topPad + chartH - ((b.high - minV) / span) * chartH;
      final yLow =
          topPad + chartH - ((b.low - minV) / span) * chartH;

      final color = b.isUp
          ? const Color(0xFF22C55E)
          : const Color(0xFFEF4444);

      // Wick
      wickPaint.color = color;
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      // Candle body
      final bodyTop = b.isUp ? yClose : yOpen;
      final bodyBot = b.isUp ? yOpen : yClose;
      final bodyH = (bodyBot - bodyTop).abs();
      candlePaint.color = color;

      if (bodyH < 0.5) {
        // Flat — draw a thin line
        canvas.drawLine(
          Offset(x - candleW / 2, bodyTop),
          Offset(x + candleW / 2, bodyTop),
          wickPaint..strokeWidth = 1.5,
        );
        wickPaint.strokeWidth = 1;
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, (bodyTop + bodyBot) / 2),
            width: candleW,
            height: bodyH,
          ),
          candlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KlinePainter oldDelegate) {
    return oldDelegate.bars != bars;
  }
}
