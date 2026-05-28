import 'package:flutter/material.dart';

/// Displays the estimated trade cost/revenue based on current price and
/// quantity field values.
class EstimateRow extends StatelessWidget {
  const EstimateRow({
    super.key,
    required this.isBuy,
    required this.price,
    required this.quantity,
  });

  static const Color _gold = Color(0xFFFFD700);
  static const Color _white = Color(0xFFF5F5F5);
  static const Color _muted = Color(0xFF8A8A8A);

  final bool isBuy;
  final double price;
  final double quantity;

  @override
  Widget build(BuildContext context) {
    final est = (price > 0 && quantity > 0) ? (price * quantity) : null;
    final label = isBuy ? '预估成交额' : '预估卖出额';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (est != null)
            Text(
              '≈ ${est.toStringAsFixed(2)} USDT',
              style: const TextStyle(
                color: _gold,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                color: _muted.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
