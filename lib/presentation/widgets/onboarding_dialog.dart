import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class WelcomeDialog extends StatefulWidget {
  final void Function(String name, double balance) onConfirm;
  const WelcomeDialog({super.key, required this.onConfirm});

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  final _nameCtrl = TextEditingController(text: '我的生涯 #1');
  final _balanceCtrl = TextEditingController(text: '100000');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      title: const Text('欢迎来到 DarkTrade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这里是一个免费练习 A 股交易的虚拟平台。\n不用担心亏损，大胆尝试你的交易策略！',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: '生涯名称',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '初始资金 (¥)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后再说'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 100000;
            if (name.isEmpty) return;
            widget.onConfirm(name, balance.clamp(1, 100000000));
          },
          child: const Text('开始交易'),
        ),
      ],
    );
  }
}
