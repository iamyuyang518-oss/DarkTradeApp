import 'package:flutter/material.dart';
import '../models/career.dart';

class GainLossCard extends StatelessWidget {
  final Career career;
  final double todayPnl;
  final Color upColor;
  final Color downColor;

  const GainLossCard({
    super.key,
    required this.career,
    required this.todayPnl,
    this.upColor = const Color(0xFF00C853),
    this.downColor = const Color(0xFFFF1744),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF222222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _statColumn('今日收益', todayPnl, todayPnl >= 0 ? upColor : downColor),
          _divider(),
          _statColumn('累计收益', career.totalPnl, career.totalPnl >= 0 ? upColor : downColor),
          _divider(),
          _statColumn('总收益率', career.totalReturnRate, career.totalReturnRate >= 0 ? upColor : downColor, suffix: '%'),
        ],
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color, {String suffix = ''}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '${value >= 0 ? "+" : ""}${value.toStringAsFixed(2)}$suffix',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.white10);
  }
}
