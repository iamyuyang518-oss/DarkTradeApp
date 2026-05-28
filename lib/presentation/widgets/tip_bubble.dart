import 'dart:math';
import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class TipData {
  TipData._();

  static const all = [
    'A 股实行 T+1 制度，今天买的股票最早明天才能卖',
    '一手 = 100 股，买股票必须按手买入',
    '涨停板是 ±10%（科创/创业板 ±20%），涨跌幅有限制的',
    '真实交易有手续费：印花税、佣金、过户费，模拟中暂不扣除',
    '绿色 = 跌、红色 = 涨（A 股习惯红涨绿跌）',
    '止损不是认输，是保护本金',
    '交易时间：工作日 9:30-11:30、13:00-15:00',
    '模拟交易里大胆试错，亏了也不怕',
    '分散投资：不要把鸡蛋放在一个篮子里',
    '换手率高说明交易活跃，也可能是短期炒作',
    '投资只能用闲钱——真实市场也一样',
    '多看少动：频繁交易的手续费会吃掉利润',
  ];
}

class TipBubble extends StatefulWidget {
  const TipBubble({super.key});

  @override
  State<TipBubble> createState() => _TipBubbleState();
}

class _TipBubbleState extends State<TipBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  String? _currentTip;
  bool _visible = false;
  final _shownTips = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTip());
  }

  void _maybeShowTip() {
    if (Random().nextDouble() < 0.2) {
      _showRandomTip();
    }
  }

  void _showRandomTip() {
    if (_visible) return;

    // Pick a tip that hasn't been shown yet
    final available = TipData.all.where((t) => !_shownTips.contains(t)).toList();
    if (available.isEmpty) {
      _shownTips.clear(); // Reset if all tips have been shown
      return;
    }

    _currentTip = available[Random().nextInt(available.length)];
    _shownTips.add(_currentTip!);
    _visible = true;
    setState(() {});
    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) setState(() => _visible = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _currentTip == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentTip!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            GestureDetector(
              onTap: () {
                _controller.reverse().then((_) {
                  if (mounted) setState(() => _visible = false);
                });
              },
              child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
