import 'package:dark_trade_app/services/market_data_service.dart';
import 'package:flutter/material.dart';

/// Trading pair selector bar.
/// Displays the selected symbol/name/price with a dropdown arrow, or a
/// placeholder prompting the user to pick a pair.
class SymbolBar extends StatelessWidget {
  const SymbolBar({super.key, required this.quote, required this.onTap});

  static const Color _gold = Color(0xFFD4A853);
  static const Color _white = Color(0xFF3D3025);
  static const Color _muted = Color(0xFFB8A080);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFE57373);

  final StockQuote? quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5EDE0),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              if (quote != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quote!.symbol,
                    style: const TextStyle(
                      color: _gold,
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
                      color: _white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  quote!.priceLabel,
                  style: TextStyle(
                    color: quote!.isUp ? _green : _red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const Icon(Icons.search, color: _muted, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '选择交易对',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
