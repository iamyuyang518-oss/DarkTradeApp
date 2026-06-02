import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';

class VipCard extends StatelessWidget {
  const VipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isVip = auth.isVip;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVip
            ? AppColors.gold.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: isVip
            ? Border.all(color: AppColors.gold, width: 1)
            : Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isVip
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : AppColors.unselectedBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(
              Icons.diamond,
              color: isVip ? AppColors.gold : AppColors.unselectedText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DarkTrade VIP',
                  style: TextStyle(
                    color: isVip ? AppColors.gold : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVip ? '已解锁加密货币市场' : '解锁加密货币市场',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isVip)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '已开通',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () async {
                await auth.activateVip();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child:
                  const Text('免费开通', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
