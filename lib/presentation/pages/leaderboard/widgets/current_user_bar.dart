import 'package:flutter/material.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/models/leaderboard_entry.dart';

class CurrentUserBar extends StatelessWidget {
  final LeaderboardEntry entry;

  const CurrentUserBar({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Username
            Expanded(
              child: Text(
                entry.username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Return rate
            Text(
              entry.totalReturnRate >= 0
                  ? '+${entry.totalReturnRate.toStringAsFixed(1)}%'
                  : '${entry.totalReturnRate.toStringAsFixed(1)}%',
              style: TextStyle(
                color: entry.totalReturnRate >= 0
                    ? AppColors.up
                    : AppColors.down,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
