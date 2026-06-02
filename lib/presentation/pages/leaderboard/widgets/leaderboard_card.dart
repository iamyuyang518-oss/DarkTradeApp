import 'package:flutter/material.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/models/leaderboard_entry.dart';

class LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isGold = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isGold ? AppColors.gold.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: isGold
            ? Border.all(color: AppColors.gold, width: 1)
            : Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Rank badge
          _buildRankBadge(),
          const SizedBox(width: 12),
          // Username + trade count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.totalTrades} 笔交易',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Return rate
          Text(
            _formatReturn(entry.totalReturnRate),
            style: TextStyle(
              color:
                  entry.totalReturnRate >= 0 ? AppColors.up : AppColors.down,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          // Win rate + PnL
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '胜率 ${entry.winRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatPnl(entry.totalPnl),
                style: TextStyle(
                  color: entry.totalPnl >= 0
                      ? AppColors.up
                      : AppColors.down,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    if (entry.rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 24));
    }
    if (entry.rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 24));
    }
    if (entry.rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 24));
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.unselectedBg,
      ),
      child: Center(
        child: Text(
          '${entry.rank}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatReturn(double rate) {
    if (rate >= 0) {
      return '+${rate.toStringAsFixed(1)}%';
    }
    return '${rate.toStringAsFixed(1)}%';
  }

  String _formatPnl(double pnl) {
    if (pnl >= 0) {
      return '¥+${pnl.toStringAsFixed(0)}';
    }
    return '¥${pnl.toStringAsFixed(0)}';
  }
}
