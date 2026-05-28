import 'package:flutter/material.dart';

/// 高端黑金个人中心：头像与 UID、功能列表、退出登录。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _white = Color(0xFFF5F5F5);
  static const Color _muted = Color(0xFF8A8A8A);
  static const Color _surface = Color(0xFF121212);
  static const Color _logoutRed = Color(0xFFDC2626);

  static const List<_MenuEntry> _menus = [
    _MenuEntry(icon: Icons.shield_outlined, title: '账号安全'),
    _MenuEntry(icon: Icons.percent_rounded, title: '费率说明'),
    _MenuEntry(icon: Icons.notifications_outlined, title: '通知设置'),
    _MenuEntry(icon: Icons.info_outline_rounded, title: '关于 DarkTrade'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: _gold.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        children: const [
                          TextSpan(
                            text: '用户 UID: ',
                            style: TextStyle(color: _white),
                          ),
                          TextSpan(
                            text: '888888',
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _menus.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 56,
                          color: _gold.withValues(alpha: 0.08),
                        ),
                      _ProfileTile(entry: _menus[i]),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _logoutRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: _gold.withValues(alpha: 0.2)),
                        ),
                        content: const Text(
                          '已退出登录（演示）',
                          style: TextStyle(color: _white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '退出登录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${entry.title}（演示）'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: ProfilePage._surface,
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ProfilePage._gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                entry.icon,
                color: ProfilePage._gold,
                size: 22,
              ),
            ),
            title: Text(
              entry.title,
              style: const TextStyle(
                color: ProfilePage._white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: ProfilePage._muted.withValues(alpha: 0.85),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
