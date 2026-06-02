import 'package:flutter/material.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/repositories/leaderboard_repository.dart';

class PeriodSelector extends StatelessWidget {
  final LeaderboardPeriod current;
  final ValueChanged<LeaderboardPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.current,
    required this.onChanged,
  });

  static const _periods = [
    (LeaderboardPeriod.weekly, '本周'),
    (LeaderboardPeriod.monthly, '本月'),
    (LeaderboardPeriod.allTime, '总榜'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _periods.map((p) {
        final (period, label) = p;
        final isSelected = current == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(period),
            selectedColor: AppColors.gold,
            backgroundColor: AppColors.unselectedBg,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
          ),
        );
      }).toList(),
    );
  }
}
