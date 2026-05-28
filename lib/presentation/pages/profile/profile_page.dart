// ignore_for_file: dead_code, prefer_const_declarations
// Reason: isLoggedIn is a P2 placeholder; logged-in code paths are intentionally present.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/presentation/pages/profile/career_management_sheet.dart';
import 'package:dark_trade_app/presentation/pages/profile/trade_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final careerService = context.watch<CareerService>();
    final isLoggedIn = false; // P2: replace with AuthService
    final activeCareer = careerService.activeCareer;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
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
                      border: Border.all(color: const Color(0xFFD4A853), width: 2),
                      color: const Color(0xFFF5EDE0),
                    ),
                    child: const Icon(Icons.person, size: 36, color: Color(0xFFD4A853)),
                  ),
                  const SizedBox(height: 12),
                  if (isLoggedIn)
                    const Column(
                      children: [
                        Text('用户名', style: TextStyle(color: Color(0xFF3D3025), fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('UID: 888888', style: TextStyle(color: Color(0xFFA09078), fontSize: 13)),
                      ],
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF9500)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('游客模式', style: TextStyle(color: Color(0xFFFF9500), fontSize: 13)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('注册/登录功能即将上线')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD4A853)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('注册 / 登录', style: TextStyle(color: Color(0xFFD4A853))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Career summary section
            if (activeCareer != null) _sectionCard(
              title: '当前生涯',
              trailing: Text(activeCareer.name, style: const TextStyle(color: Color(0xFFD4A853))),
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFFFFFFFF),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const CareerManagementSheet(),
              ),
            ),
            const SizedBox(height: 12),
            // Menu items
            _menuCard(context, [
              _menuItem('生涯管理', Icons.sports_esports, () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFFFFFFFF),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => const CareerManagementSheet(),
                );
              }),
              _menuItem('交易记录', Icons.receipt_long, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeHistoryPage()));
              }),
              if (isLoggedIn) _menuItem('修改密码', Icons.lock_outline, () {}),
              _menuItem('关于 DarkTrade', Icons.info_outline, () {
                showAboutDialog(
                  context: context,
                  applicationName: 'DarkTrade',
                  applicationVersion: 'v2.0.0',
                  applicationLegalese: '模拟交易平台 — 投资有风险，入市需谨慎',
                );
              }),
            ]),
            const SizedBox(height: 24),
            if (isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // P2: implement logout
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('退出登录', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            const SizedBox(height: 16),
            const Center(
              child: Text('DarkTrade v2.0.0', style: TextStyle(color: Color(0xFFC4B898), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFFA09078), fontSize: 14)),
            if (trailing != null) trailing,
            if (trailing == null) const Icon(Icons.chevron_right, color: Color(0xFFC4B898)),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
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
          color: const Color(0xFFD4A853).withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFD4A853), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Color(0xFF3D3025))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFC4B898)),
      onTap: onTap,
    );
  }
}
