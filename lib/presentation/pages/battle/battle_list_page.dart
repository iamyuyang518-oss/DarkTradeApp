import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/battle_service.dart';
import 'package:dark_trade_app/presentation/pages/battle/widgets/battle_room_card.dart';
import 'package:dark_trade_app/presentation/pages/battle/widgets/create_battle_sheet.dart';
import 'package:dark_trade_app/presentation/pages/battle/widgets/join_battle_sheet.dart';
import 'package:dark_trade_app/presentation/pages/battle/battle_detail_page.dart';
import 'package:dark_trade_app/presentation/pages/profile/auth_sheet.dart';

class BattleListPage extends StatefulWidget {
  const BattleListPage({super.key});

  @override
  State<BattleListPage> createState() => _BattleListPageState();
}

class _BattleListPageState extends State<BattleListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isLoggedIn) {
        context.read<BattleService>().fetchUserRooms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final battle = context.watch<BattleService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('好友对战'),
        backgroundColor: AppColors.background,
      ),
      body: _buildBody(auth, battle),
    );
  }

  Widget _buildBody(AuthService auth, BattleService battle) {
    // Guest state
    if (!auth.isLoggedIn) {
      return _buildGuestLock(context);
    }

    // Loading state
    if (battle.isLoading && battle.rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    // Error state
    if (battle.error != null && battle.rooms.isEmpty) {
      return _buildErrorState(battle);
    }

    // Empty state or data
    return Column(
      children: [
        Expanded(
          child: battle.rooms.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: battle.rooms.length,
                  itemBuilder: (_, i) => BattleRoomCard(
                    room: battle.rooms[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BattleDetailPage(roomId: battle.rooms[i].id),
                        ),
                      );
                    },
                  ),
                ),
        ),
        // Bottom action bar
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildGuestLock(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 64, color: AppColors.unselectedText),
            const SizedBox(height: 16),
            const Text(
              '登录后参与好友对战',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '注册账号，与好友一较高下',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAuthSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(AppText.registerLogin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BattleService battle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              battle.error ?? '加载失败',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => battle.fetchUserRooms(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
              ),
              child:
                  const Text('重试', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🏆', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              '暂无对战记录',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '邀请好友一起来对战吧',
              style: TextStyle(
                color: AppColors.unselectedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusLg)),
                    ),
                    builder: (_) => const CreateBattleSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('创建房间'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusLg)),
                    ),
                    builder: (_) => const JoinBattleSheet(),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('加入房间',
                    style: TextStyle(color: AppColors.gold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (_) => const AuthSheet(),
    );
  }
}
