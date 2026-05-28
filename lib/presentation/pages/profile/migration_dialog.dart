import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class MigrationDialog extends StatelessWidget {
  final int careerCount;
  final VoidCallback onImport;
  final VoidCallback onSkip;

  const MigrationDialog({
    super.key,
    required this.careerCount,
    required this.onImport,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      title: const Text('导入本地数据'),
      content: Text('检测到本地有 $careerCount 个交易生涯，是否导入到你的账户？\n\n'
          '导入后，你可以在任何设备上查看这些数据。'),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: const Text('不导入'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
          ),
          onPressed: onImport,
          child: const Text('导入'),
        ),
      ],
    );
  }
}
