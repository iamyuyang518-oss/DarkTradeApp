import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/live_market_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/us_stock_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bottom sheet that lists all available trading pairs across crypto, US
/// stocks, and A-shares, with a search field for filtering.
class SymbolPickerSheet extends StatefulWidget {
  const SymbolPickerSheet({super.key});

  @override
  State<SymbolPickerSheet> createState() => _SymbolPickerSheetState();
}

class _SymbolPickerSheetState extends State<SymbolPickerSheet> {
  static const Color _gold = Color(0xFFD4A853);
  static const Color _white = Color(0xFF3D3025);
  static const Color _muted = Color(0xFFB8A080);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFE57373);

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
              color: _gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: _white, fontSize: 15),
              cursorColor: _gold,
              decoration: InputDecoration(
                hintText: '搜索交易对...',
                hintStyle: const TextStyle(color: _muted, fontSize: 15),
                prefixIcon:
                    const Icon(Icons.search, color: _muted, size: 22),
                filled: true,
                fillColor: const Color(0xFFF5EDE0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _gold.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _gold.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _gold.withValues(alpha: 0.5)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      '无匹配结果',
                      style: TextStyle(color: _muted, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: _gold.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (ctx, i) {
                      final q = filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          q.symbol,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          q.name,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          q.priceLabel,
                          style: TextStyle(
                            color: q.isUp ? _green : _red,
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
