import 'package:flutter/material.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/local/models/career.dart';

class GainLossCard extends StatelessWidget {
  final Career career;
  final double todayPnl;
  final Color upColor;
  final Color downColor;

  const GainLossCard({
    super.key,
    required this.career,
    required this.todayPnl,
    this.upColor = AppColors.up,
    this.downColor = AppColors.down,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.goldBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}
