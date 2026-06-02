import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Responsive app shell: sidebar on desktop (>=900px), bottom nav on mobile.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.pages,
    required this.labels,
    required this.icons,
    required this.activeIcons,
  });

  final List<Widget> pages;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> activeIcons;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        if (isWide) {
          return _buildSidebarLayout(isCompact: false);
        } else if (isMedium) {
          return _buildSidebarLayout(isCompact: true);
        } else {
          return _buildBottomNavLayout();
        }
      },
    );
  }

  /// Desktop: fixed sidebar + content area.
  Widget _buildSidebarLayout({required bool isCompact}) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            currentIndex: _currentIndex,
            isCompact: isCompact,
            isLoggedIn: auth.isLoggedIn,
            username: auth.username,
            userId: auth.userId,
            labels: widget.labels,
            icons: widget.icons,
            activeIcons: widget.activeIcons,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
          // Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: widget.pages,
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile: bottom navigation bar (original behavior).
  Widget _buildBottomNavLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: List.generate(widget.labels.length, (i) {
          final selected = i == _currentIndex;
          return BottomNavigationBarItem(
            icon: Icon(selected ? widget.activeIcons[i] : widget.icons[i]),
            label: widget.labels[i],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentIndex,
    required this.isCompact,
    required this.isLoggedIn,
    required this.username,
    required this.userId,
    required this.labels,
    required this.icons,
    required this.activeIcons,
    required this.onTap,
  });

  final int currentIndex;
  final bool isCompact;
  final bool isLoggedIn;
  final String? username;
  final String? userId;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> activeIcons;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final w = isCompact ? 72.0 : AppDimens.sidebarWidth;

    return Container(
      width: w,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF6),
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          // Logo
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DarkTrade',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.show_chart, color: AppColors.gold, size: 24),
            ),
          const SizedBox(height: 28),
          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
              children: List.generate(labels.length, (i) {
                final selected = i == currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _NavItem(
                    icon: selected ? activeIcons[i] : icons[i],
                    label: isCompact ? '' : labels[i],
                    selected: selected,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
          // User card at bottom
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.goldBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('😎', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username ?? '游客',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'UID: ${userId?.substring(0, 8) ?? '---'}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: label.isEmpty ? 0 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            boxShadow: selected ? AppShadows.goldButton : null,
          ),
          child: label.isEmpty
              ? Center(
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: selected ? Colors.white : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
