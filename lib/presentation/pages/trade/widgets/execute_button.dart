import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

/// Full-width gradient execute button with heavy drop shadow.
class ExecuteButton extends StatelessWidget {
  const ExecuteButton({super.key, required this.isBuy, required this.onPressed});

  final bool isBuy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = isBuy ? AppColors.up : AppColors.down;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.12),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.goldDark],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '确认交易',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
