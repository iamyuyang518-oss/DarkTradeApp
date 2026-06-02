import 'package:flutter/material.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/models/battle_room.dart';

class BattleRoomCard extends StatelessWidget {
  final BattleRoom room;
  final VoidCallback? onTap;

  const BattleRoomCard({super.key, required this.room, this.onTap});

  Color _statusColor() {
    switch (room.status) {
      case BattleRoomStatus.waiting:
        return AppColors.gold;
      case BattleRoomStatus.active:
        return AppColors.up;
      case BattleRoomStatus.completed:
        return AppColors.textSecondary;
      case BattleRoomStatus.cancelled:
        return AppColors.unselectedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room.status.displayLabel,
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info row
            Row(
              children: [
                _infoChip(
                    Icons.schedule, '${room.durationDays}天 · ¥${room.initialBalance.toInt()}'),
                const Spacer(),
                if (room.status == BattleRoomStatus.active &&
                    room.endsAt != null)
                  Text(
                    room.countdownText,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (room.status == BattleRoomStatus.completed &&
                    room.winnerId != null)
                  const Text('👑', style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
