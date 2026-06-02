import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/battle_service.dart';

class CreateBattleSheet extends StatefulWidget {
  const CreateBattleSheet({super.key});

  @override
  State<CreateBattleSheet> createState() => _CreateBattleSheetState();
}

class _CreateBattleSheetState extends State<CreateBattleSheet> {
  final _nameCtrl = TextEditingController(text: '好友对战');
  int _durationDays = 3;
  bool _loading = false;
  String? _error;

  static const _durations = [
    (1, '1天'),
    (3, '3天'),
    (7, '7天'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            const Center(
              child: SizedBox(
                width: 40,
                child: Divider(color: Color(0xFFC4B898), thickness: 3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '创建对战房间',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Name field
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: '房间名称',
                hintText: '给对战起个名字',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Duration selector
            const Text(
              '对战时长',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _durations.map((d) {
                final (days, label) = d;
                final isSelected = _durationDays == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _durationDays = days),
                    selectedColor: AppColors.gold,
                    backgroundColor: AppColors.unselectedBg,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusSm),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '初始资金 ¥100,000 · 邀请码将在创建后生成',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.down, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.gold.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('创建房间', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入房间名称');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final battleService = context.read<BattleService>();
    final code = await battleService.createRoom(name, _durationDays);

    if (!mounted) return;

    setState(() => _loading = false);

    if (code != null) {
      Navigator.pop(context);
      _showInviteCodeDialog(code);
    } else {
      setState(() => _error = battleService.error ?? '创建失败');
    }
  }

  void _showInviteCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.gold, size: 28),
            SizedBox(width: 8),
            Text('房间已创建',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '将邀请码发送给好友',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('邀请码已复制')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold),
                    foregroundColor: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Share.share(
                        '快来 DarkTrade 和我对战！邀请码: $code');
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('分享'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold),
                    foregroundColor: AppColors.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的',
                style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}
