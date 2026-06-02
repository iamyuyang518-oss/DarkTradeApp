import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/battle_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/presentation/pages/battle/battle_detail_page.dart';

class JoinBattleSheet extends StatefulWidget {
  const JoinBattleSheet({super.key});

  @override
  State<JoinBattleSheet> createState() => _JoinBattleSheetState();
}

class _JoinBattleSheetState extends State<JoinBattleSheet> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
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
              '加入对战',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Invite code input
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                letterSpacing: 10,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '输入 6 位邀请码',
                hintStyle: const TextStyle(
                  color: AppColors.unselectedText,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
                counterText: '',
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
            // Error
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.down, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _joinRoom,
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
                    : const Text('加入', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _joinRoom() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = '请输入 6 位邀请码');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final battleService = context.read<BattleService>();
    final careerService = context.read<CareerService>();

    final room = await battleService.joinRoom(
      code,
      createCareer: (name, initialBalance) async {
        return careerService.createCareer(name, initialBalance);
      },
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (room != null) {
      Navigator.pop(context);
      // Navigate to battle detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BattleDetailPage(roomId: room.id),
        ),
      );
    } else {
      setState(() => _error = battleService.error ?? '加入失败');
    }
  }
}
