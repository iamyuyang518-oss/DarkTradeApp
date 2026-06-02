import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/achievement_service.dart';
import 'package:dark_trade_app/presentation/pages/profile/auth_sheet.dart';
import 'package:dark_trade_app/presentation/pages/profile/career_management_sheet.dart';
import 'package:dark_trade_app/presentation/pages/tutorial/tutorial_page.dart';
import 'package:dark_trade_app/presentation/pages/leaderboard/leaderboard_page.dart';
import 'package:dark_trade_app/presentation/pages/profile/forgot_password_sheet.dart';
import 'package:dark_trade_app/presentation/pages/profile/trade_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final careerService = context.watch<CareerService>();
    final isLoggedIn = auth.isLoggedIn;
    final activeCareer = careerService.activeCareer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            // Avatar + identity
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                      color: AppColors.unselectedBg,
                    ),
                    child: const Icon(Icons.person, size: 36, color: AppColors.gold),
                  ),
                  const SizedBox(height: 12),
                  if (isLoggedIn)
                    Column(
                      children: [
                        Text(
                          auth.username ?? '用户',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UID: ${auth.userId?.substring(0, 8) ?? '---'}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.unselectedText),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '游客模式',
                        style: TextStyle(color: AppColors.unselectedText, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () => _showAuthSheet(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                        ),
                        child: const Text(
                          AppText.registerLogin,
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Career summary section
            if (activeCareer != null)
              _sectionCard(
                title: '当前生涯',
                trailing: Text(activeCareer.name, style: const TextStyle(color: AppColors.gold)),
                onTap: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
                  ),
                  builder: (_) => const CareerManagementSheet(),
                ),
              ),
            const SizedBox(height: 12),
            _buildAchievementSection(context),
            const SizedBox(height: 12),
            // Menu items
            _menuCard(context, [
              _menuItem('生涯管理', Icons.sports_esports, () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
                  ),
                  builder: (_) => const CareerManagementSheet(),
                );
              }),
              _menuItem('交易记录', Icons.receipt_long, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeHistoryPage()));
              }),
              _menuItem('排行榜', Icons.leaderboard, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()));
              }),
              _menuItem('新手教程', Icons.school, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialPage()));
              }),
              if (isLoggedIn)
                _menuItem('修改密码', Icons.lock_outline, () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusLg)),
                    ),
                    builder: (_) => const ForgotPasswordSheet(),
                  );
                }),
              _menuItem('关于 DarkTrade', Icons.info_outline, () {
                showAboutDialog(
                  context: context,
                  applicationName: AppText.appName,
                  applicationVersion: 'v2.0.0',
                  applicationLegalese: AppText.disclaimerFooter,
                );
              }),
            ]),
            const SizedBox(height: 24),
            if (isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await auth.logout();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.down),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('退出登录', style: TextStyle(color: AppColors.down)),
                ),
              ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'DarkTrade v2.0.0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (_) => const AuthSheet(),
    );
  }

  Widget _sectionCard({required String title, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            if (trailing != null) trailing,
            if (trailing == null) const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildAchievementSection(BuildContext context) {
    final achievementService = context.watch<AchievementService>();
    final achievements = achievementService.achievements;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('成就勋章', style: TextStyle(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
              Text('${achievementService.unlocked.length}/${achievements.length}',
                style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) {
              final unlocked = a.unlocked;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked ? AppColors.gold.withValues(alpha: 0.1) : AppColors.unselectedBg,
                      border: Border.all(
                        color: unlocked ? AppColors.gold : AppColors.border,
                        width: unlocked ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unlocked ? a.emoji : '🔒',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: unlocked ? AppColors.textPrimary : AppColors.unselectedText,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
