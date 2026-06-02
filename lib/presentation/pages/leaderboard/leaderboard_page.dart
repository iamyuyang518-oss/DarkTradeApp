import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/leaderboard_service.dart';
import 'package:dark_trade_app/presentation/pages/leaderboard/widgets/period_selector.dart';
import 'package:dark_trade_app/presentation/pages/leaderboard/widgets/leaderboard_card.dart';
import 'package:dark_trade_app/presentation/pages/leaderboard/widgets/current_user_bar.dart';
import 'package:dark_trade_app/presentation/pages/profile/auth_sheet.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isLoggedIn) {
        context.read<LeaderboardService>().fetchLeaderboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final lb = context.watch<LeaderboardService>();

    return Column(
      children: [
        // Warm header
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            '🏆 排行榜',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: _buildBody(auth, lb)),
      ],
    );
  }

  Widget _buildBody(AuthService auth, LeaderboardService lb) {
    // Guest state
    if (!auth.isLoggedIn) {
      return _buildGuestLock(context);
    }

    // Loading state
    if (lb.isLoading && lb.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    // Error state
    if (lb.error != null && lb.entries.isEmpty) {
      return _buildErrorState(lb);
    }

    // Data state (possibly empty)
    return Column(
      children: [
        // Period selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PeriodSelector(
            current: lb.period,
            onChanged: (p) => lb.setPeriod(p),
          ),
        ),
        // List or empty
        Expanded(
          child: lb.entries.isEmpty ? _buildEmptyState() : _buildRankList(lb),
        ),
        // Sticky current user bar (if not in top 50)
        if (lb.currentUserEntry != null && !lb.currentUserInList)
          CurrentUserBar(entry: lb.currentUserEntry!),
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
              '登录后查看排行榜，与全球交易者一较高下 🏆',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '注册账号，与全球交易者一较高下',
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

  Widget _buildErrorState(LeaderboardService lb) {
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
              lb.error ?? '加载失败',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => lb.fetchLeaderboard(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
              ),
              child: const Text('重试',
                  style: TextStyle(color: AppColors.gold)),
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
              '暂无排名数据',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '成为第一个上榜的交易者吧',
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

  Widget _buildRankList(LeaderboardService lb) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: lb.entries.length,
      itemBuilder: (_, i) => LeaderboardCard(entry: lb.entries[i]),
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
