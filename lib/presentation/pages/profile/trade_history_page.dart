import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';

class TradeHistoryPage extends StatefulWidget {
  const TradeHistoryPage({super.key});

  @override
  State<TradeHistoryPage> createState() => _TradeHistoryPageState();
}

class _TradeHistoryPageState extends State<TradeHistoryPage> {
  int _selectedDays = 0; // 0 = all
  static const _filters = [0, 7, 30];

  @override
  Widget build(BuildContext context) {
    final careerId = context.watch<CareerService>().activeCareer?.id;
    final history = context.watch<TradeHistoryService>();
    final records = careerId != null
        ? history.getRecordsForCareerFiltered(careerId, days: _selectedDays)
        : <TradeRecord>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text('交易记录', style: TextStyle(color: Color(0xFF3D3025))),
        backgroundColor: const Color(0xFFFFFBF5),
        iconTheme: const IconThemeData(color: Color(0xFFD4A853)),
      ),
      body: Column(
        children: [
          _filterRow(),
          Expanded(child: records.isEmpty ? _emptyState() : _listView(records)),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((d) {
          final isSelected = _selectedDays == d;
          final label = d == 0 ? '全部' : '近$d天';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedDays = d),
              selectedColor: const Color(0xFFD4A853),
              backgroundColor: const Color(0xFFF5EDE0),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF3D3025),
              ),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('还没有交易记录', style: TextStyle(color: Color(0xFFA09078), fontSize: 16)),
          SizedBox(height: 4),
          Text('去行情页看看吧 👀', style: TextStyle(color: Color(0xFFC4B898), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _listView(List<TradeRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (_, i) => _recordTile(records[i]),
    );
  }

  Widget _recordTile(TradeRecord r) {
    final isBuy = r.type == TradeType.buy;
    final color = isBuy ? const Color(0xFF00C853) : const Color(0xFFFF1744);
    final label = isBuy ? '买' : '卖';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(color: Color(0xFF3D3025), fontSize: 15)),
                Text(r.symbol, style: const TextStyle(color: Color(0xFFA09078), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r.quantity.toStringAsFixed(4),
                style: const TextStyle(color: Color(0xFF3D3025), fontSize: 14),
              ),
              Text(
                '@ \$${r.price.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFFA09078), fontSize: 12),
              ),
            ],
          ),
          if (r.pnl != null) ...[
            const SizedBox(width: 12),
            Text(
              '${r.pnl! >= 0 ? "+" : ""}${r.pnl!.toStringAsFixed(2)}',
              style: TextStyle(
                color: r.pnl! >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF1744),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
