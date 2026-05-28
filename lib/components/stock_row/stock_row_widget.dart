import 'package:flutter/material.dart';

class StockRowWidget extends StatefulWidget {
  const StockRowWidget({
    super.key,
    required this.change,
    required this.chartData,
    required this.name,
    required this.price,
    required this.symbol,
    required this.isUp,
    this.expanded = false,
    this.onTap,
    this.onTradeTap,
    this.onDetailTap,
    this.onArrowTap,
  });

  final String change;
  final String chartData;
  final String name;
  final String price;
  final String symbol;
  final bool isUp;
  final bool expanded;
  final VoidCallback? onTap;
  final VoidCallback? onTradeTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onArrowTap;

  @override
  State<StockRowWidget> createState() => _StockRowWidgetState();
}

class _StockRowWidgetState extends State<StockRowWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController;
  late final Animation<double> _arrowTurn;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowTurn = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    if (widget.expanded) _arrowController.value = 1;
  }

  @override
  void didUpdateWidget(covariant StockRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _arrowController.forward();
      } else {
        _arrowController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  List<double> get _points {
    return widget.chartData
        .split(',')
        .map((e) => double.tryParse(e.trim()) ?? 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final pts = _points;
    final theme = Theme.of(context);
    final up = widget.isUp;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---- header row -----------------------------------------------
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.symbol,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.price,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.change,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: up
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onArrowTap,
                    behavior: HitTestBehavior.opaque,
                    child: RotationTransition(
                      turns: _arrowTurn,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                ],
              ),

              // ---- expanded sparkline ---------------------------------------
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: widget.expanded && pts.length >= 2
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                              height: 48,
                              child: CustomPaint(
                                size: const Size(double.infinity, 48),
                                painter: _SparklinePainter(
                                  points: pts,
                                  color: up
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                          if (widget.onTradeTap != null ||
                              widget.onDetailTap != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (widget.onDetailTap != null)
                                  GestureDetector(
                                    onTap: widget.onDetailTap,
                                    child: const Text(
                                      '详情 →',
                                      style: TextStyle(
                                        color: Color(0xFFF5F5F5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (widget.onTradeTap != null &&
                                    widget.onDetailTap != null)
                                  const SizedBox(width: 16),
                                if (widget.onTradeTap != null)
                                  GestureDetector(
                                    onTap: widget.onTradeTap,
                                    child: const Text(
                                      '去交易 →',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height - ((points[i] - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
