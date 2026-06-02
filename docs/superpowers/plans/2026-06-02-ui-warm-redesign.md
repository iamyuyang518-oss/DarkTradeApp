# UI Warm Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deeply optimize DarkTrade's UI with warm nurturing visual language, market sentiment system, web-first sidebar layout, and encouraging micro-copy — all while keeping existing functionality intact.

**Architecture:** Five sequential phases. Phase 1 updates the design token foundation (colors, dimensions, shadows). Phase 2 restructures the app shell from mobile bottom-tabs to a responsive sidebar+content layout. Phase 3 adds the market sentiment service and its UI widgets. Phase 4 replaces all user-facing copy with warm, encouraging alternatives. Phase 5 adds hover micro-interactions.

**Tech Stack:** Flutter 3.x, Dart, Provider, google_fonts, Material 3

---

### Task 1: Update Design Tokens — AppColors, AppDimens, new shadow constants

**Files:**
- Modify: `lib/core/constants.dart`

- [ ] **Step 1: Replace AppColors with new warm palette**

Replace the entire `AppColors` class in `lib/core/constants.dart`:

```dart
abstract class AppColors {
  AppColors._();

  // 背景与表面
  static const Color background = Color(0xFFFFF9F0);
  static const Color surface = Color(0xFFFFFEFB);
  static const Color border = Color(0xFFECDCC0);

  // 强调色 — 金色系
  static const Color gold = Color(0xFFD4A853);
  static const Color goldDark = Color(0xFFC49B38);
  static const Color goldBg = Color(0xFFFDF6E8);
  static const Color goldBorder = Color(0xFFF5E6C8);

  // 文字
  static const Color textPrimary = Color(0xFF4A3828);
  static const Color textSecondary = Color(0xFFB8977A);
  static const Color textMuted = Color(0xFFC8B898);

  // 涨跌
  static const Color up = Color(0xFF5CB860);
  static const Color upBg = Color(0xFFE8F5E9);
  static const Color down = Color(0xFFE88580);
  static const Color downBg = Color(0xFFFFF0F0);

  // 非选中（保留兼容旧引用）
  static const Color unselectedBg = Color(0xFFF5EDE0);
  static const Color unselectedText = Color(0xFFB8976A);

  // 导航（保留兼容旧引用，Phase 2 改用 Sidebar）
  static const Color navBg = Color(0xFFFFF9F0);
  static const Color navSelected = Color(0xFFD4A853);
  static const Color navUnselected = Color(0xFFB8977A);

  // 情绪色板
  static const Color emotionZen = Color(0xFFB8D4C8);
  static const Color emotionZenBg = Color(0xFFEDF5F0);
  static const Color emotionPopcorn = Color(0xFFF5E6C8);
  static const Color emotionPopcornBg = Color(0xFFFDF6E8);
  static const Color emotionFire = Color(0xFFF0C8C0);
  static const Color emotionFireBg = Color(0xFFFDF2F0);
}
```

- [ ] **Step 2: Update AppDimens with unified border radius and new page padding**

Replace the `AppDimens` class:

```dart
abstract class AppDimens {
  AppDimens._();

  // 圆角统一
  static const double radiusXs = 4.0;   // 小标签
  static const double radiusSm = 8.0;   // 芯片/标签
  static const double radiusMd = 12.0;  // 按钮/输入框/侧边栏导航
  static const double radiusLg = 16.0;  // 卡片
  static const double radiusXl = 18.0;  // 弹窗/底部面板

  // 间距
  static const double paddingPage = 20.0;
  static const double paddingCard = 16.0;
  static const double gapXs = 4.0;
  static const double gapSm = 8.0;
  static const double gapMd = 12.0;
  static const double gapLg = 16.0;

  // 侧边栏
  static const double sidebarWidth = 220.0;
}
```

- [ ] **Step 3: Add AppShadows class after AppDimens**

```dart
abstract class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x0AA08C6E),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const hover = [
    BoxShadow(
      color: Color(0x1FD4A853),
      blurRadius: 24,
      offset: Offset(0, 6),
    ),
  ];

  static const modal = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  static const goldButton = [
    BoxShadow(
      color: Color(0x4DD4A853),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}
```

- [ ] **Step 4: Update AppText with new warm copy**

Replace the `AppText` class:

```dart
abstract class AppText {
  AppText._();
  static const String appName = 'DarkTrade';
  static const String tagline = 'A 股模拟交易练习平台';
  static const String guestBanner = '游客模式，数据仅保存在本设备';
  static const String registerLogin = '注册 / 登录';
  static const String disclaimerFooter = '模拟交易 · 仅供学习 · 不构成投资建议';
  static const String dataDelayNote = '行情数据可能存在五分钟延迟';
  static const String riskTitle = '风险提示';
  static const String riskBody =
      '本平台为模拟交易工具，所有资金均为虚拟资金。\n'
      '行情数据来源于公开接口，可能存在五分钟延迟。\n'
      '模拟交易体验不代表真实市场表现。\n'
      '本平台不构成任何投资建议。\n'
      '股市有风险，投资需谨慎。';
  static const String agreeTerms = '我已了解并同意用户协议和隐私政策';

  // New warm copy
  static const String emptyHoldings = '还没有持仓哦，去探索市场吧~';
  static const String emptyWatchlist = '去热门发现感兴趣的股票，点 ☆ 加入关注';
  static const String emptyWatchlistTitle = '还没有关注股票';
  static const String emptyHoldingsTitle = '暂无持仓';
  static const String noMatchResult = '没有匹配结果';
  static const String tryOtherSearch = '试试其他搜索词';
  static const String loadingData = '数据正在路上... 🚀';
  static const String networkError = '网络开了小差，点此重试 🔄';
  static const String tradeSuccess = '成交！离大佬又近了一步 👍';
  static const String balanceInsufficient = '差一点就够啦，调整一下数量？';
  static const String newbieTip = '建议先用 25% 仓位小试牛刀~';
  static const String highFrequency(String count) => '本周已交易 $count 次，注意休息！喝杯茶 🍵';
}
```

- [ ] **Step 5: Verify the file compiles**

Run: `cd D:/DarkTradeApp && dart analyze lib/core/constants.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/constants.dart
git commit -m "feat(ui): update design tokens — warm palette, unified radii, shadows, new copy"
```

---

### Task 2: Update ThemeData to use new tokens

**Files:**
- Modify: `lib/core/theme.dart`

- [ ] **Step 1: Rewrite AppTheme.light with new tokens**

Replace the contents of `lib/core/theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.gold,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.down,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.goldBg,
        selectedColor: AppColors.gold,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        side: BorderSide.none,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 34,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gold),
          foregroundColor: AppColors.gold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd D:/DarkTradeApp && dart analyze lib/core/theme.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme.dart
git commit -m "feat(ui): update ThemeData with new warm design tokens"
```

---

### Task 3: Remove duplicate local color constants across pages

**Files:**
- Modify: `lib/presentation/pages/market/market_page.dart`
- Modify: `lib/presentation/pages/market/stock_detail_page.dart`
- Modify: `lib/presentation/pages/trade/trade_page.dart`
- Modify: `lib/presentation/pages/trade/widgets/side_toggle.dart`
- Modify: `lib/presentation/pages/trade/widgets/execute_button.dart`
- Modify: `lib/presentation/pages/trade/widgets/labeled_field.dart`
- Modify: `lib/presentation/widgets/gain_loss_card.dart`
- Modify: `lib/presentation/widgets/equity_curve_chart.dart`

- [ ] **Step 1: Replace local colors in market_page.dart**

In `lib/presentation/pages/market/market_page.dart`, remove lines 32-43 (the local static const colors) and replace all references:

Remove:
```dart
  static const Color _amber = Color(0xFFD4A853);
  static const Color _bg = Color(0xFFFFFBF5);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF3D3025);
  static const Color _textSecondary = Color(0xFFA09078);
  static const Color _textMuted = Color(0xFFC4B898);
  static const Color _border = Color(0xFFE8DCC8);
  static const Color _chipBg = Color(0xFFF5EDE0);
  static const Color _greenBg = Color(0xFFE8F5E9);
  static const Color _redBg = Color(0xFFFFF0F0);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFE57373);
```

Replace usage throughout the file:
- `_amber` → `AppColors.gold`
- `_bg` → `AppColors.background`
- `_cardBg` → `AppColors.surface`
- `_textPrimary` → `AppColors.textPrimary`
- `_textSecondary` → `AppColors.textSecondary`
- `_textMuted` → `AppColors.textMuted`
- `_border` → `AppColors.border`
- `_chipBg` → `AppColors.goldBg`
- `_greenBg` → `AppColors.upBg`
- `_redBg` → `AppColors.downBg`
- `_green` → `AppColors.up`
- `_red` → `AppColors.down`

Add import if not already present: `import 'package:dark_trade_app/core/constants.dart';`

- [ ] **Step 2: Replace local colors in stock_detail_page.dart**

In `lib/presentation/pages/market/stock_detail_page.dart`, remove lines 29-36 (local static const colors) and replace all references with `AppColors.*` equivalents.

- [ ] **Step 3: Replace local colors in trade_page.dart**

In `lib/presentation/pages/trade/trade_page.dart`, remove lines 29-31:
```dart
  static const Color bg = Color(0xFFFFFBF5);
  static const Color gold = Color(0xFFD4A853);
  static const Color white = Color(0xFF3D3025);
```

Replace: `TradePage.bg` → `AppColors.background`, `TradePage.gold` → `AppColors.gold`, `TradePage.white` → `AppColors.textPrimary`.

In the SnackBar (lines 96-123), update colors:
- `const Color(0xFF0A0A0A)` → `AppColors.textPrimary` (for background)
- `TradePage.gold.withValues(alpha: 0.45)` → `AppColors.gold.withValues(alpha: 0.45)`
- `TradePage.white` → `AppColors.textPrimary`

- [ ] **Step 4: Replace local colors in trade widgets**

In `lib/presentation/pages/trade/widgets/side_toggle.dart`:
- Replace `_gold` reference with `AppColors.gold`
- Replace `_green` with `AppColors.up`
- Replace `_red` with `AppColors.down`
- Replace `_idleBg` with `AppColors.goldBg`
- Replace `_idleText` with `AppColors.textSecondary`
- Add `import 'package:dark_trade_app/core/constants.dart';`

In `lib/presentation/pages/trade/widgets/execute_button.dart`:
- Replace `_gold` with `AppColors.gold`
- Replace `_green` with `AppColors.up`
- Replace `_red` with `AppColors.down`
- Update button label from `'立即执行'` to `_c.isBuy ? '确认买入' : '确认卖出'` — wait, this button doesn't have access to `_c`. Just update the label to `'确认交易'` and the colors. The button's `isBuy` prop already controls the accent color. Update gradient to use `AppColors.gold` and `AppColors.goldDark`.
- Add import.

In `lib/presentation/pages/trade/widgets/labeled_field.dart`:
- Replace `_gold` with `AppColors.gold`
- Replace `_white` with `AppColors.textPrimary`
- Replace `_muted` with `AppColors.textSecondary`
- Replace `_bg` with `AppColors.goldBg`
- Add import.

- [ ] **Step 5: Replace local colors in shared widgets**

In `lib/presentation/widgets/gain_loss_card.dart`:
- Replace `upColor` default `Color(0xFF00C853)` → `AppColors.up`
- Replace `downColor` default `Color(0xFFFF1744)` → `AppColors.down`
- Replace inline `Color(0xFFA09078)` → `AppColors.textSecondary`
- Replace inline `Color(0xFFE8DCC8)` → `AppColors.border`
- Replace gradient `Color(0xFFFFFFFF)` → `AppColors.surface`
- Replace gradient `Color(0xFFF5EDE0)` → `AppColors.goldBg`
- Update border radius to `AppDimens.radiusLg`
- Update card padding to use `AppDimens.paddingCard`
- Add import for constants.

In `lib/presentation/widgets/equity_curve_chart.dart`:
- Replace inline `Color(0xFFFFFFFF)` → `AppColors.surface`
- Replace inline `Color(0xFFA09078)` → `AppColors.textSecondary`
- Replace `Color(0xFFD4A853)` → `AppColors.gold`
- Update border radius to `AppDimens.radiusMd`
- Add import for constants.

- [ ] **Step 6: Run analyzer to verify no broken references**

Run: `cd D:/DarkTradeApp && dart analyze lib/`
Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/
git commit -m "refactor(ui): replace all local color constants with centralized AppColors tokens"
```

---

### Task 4: Create the AppShell widget (responsive sidebar + content area)

**Files:**
- Create: `lib/presentation/widgets/app_shell.dart`

- [ ] **Step 1: Write AppShell**

Create `lib/presentation/widgets/app_shell.dart`:

```dart
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
                      decoration: BoxDecoration(
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
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/widgets/app_shell.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/app_shell.dart
git commit -m "feat(ui): add AppShell — responsive sidebar+content layout"
```

---

### Task 5: Refactor MainTabsPage to use AppShell

**Files:**
- Modify: `lib/app/main_tabs_page.dart`

- [ ] **Step 1: Rewrite MainTabsPage as a thin wrapper around AppShell**

Replace the contents of `lib/app/main_tabs_page.dart`:

```dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/achievement_service.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';
import 'package:dark_trade_app/presentation/pages/assets/assets_page.dart';
import 'package:dark_trade_app/presentation/pages/market/market_page.dart';
import 'package:dark_trade_app/presentation/pages/profile/profile_page.dart';
import 'package:dark_trade_app/presentation/pages/trade/trade_page.dart';
import 'package:dark_trade_app/presentation/widgets/app_shell.dart';
import 'package:dark_trade_app/presentation/widgets/guest_banner.dart';
import 'package:dark_trade_app/presentation/widgets/onboarding_dialog.dart';
import 'package:dark_trade_app/presentation/widgets/risk_disclaimer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Entry shell: responsive sidebar/bottom-nav + onboarding flow.
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  bool _disclaimerShown = false;
  late final TradeSelectionService _tradeSelection;

  late final List<Widget> _pages = const [
    MarketExplorerWidget(),
    AssetsPage(),
    TradePage(),
    ProfilePage(),
  ];

  static const _labels = ['行情', '资产', '交易', '个人'];
  static const _icons = [
    Icons.show_chart_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.swap_horiz_outlined,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.show_chart,
    Icons.account_balance_wallet,
    Icons.swap_horiz,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final careerService = context.read<CareerService>();
    final tradeHistory = context.read<TradeHistoryService>();
    final watchlistService = context.read<WatchlistService>();
    auth.wireServices(careerService, tradeHistory, watchlistService);
    _tradeSelection = context.read<TradeSelectionService>();
    _tradeSelection.addListener(_onTradeSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  void _checkOnboarding() {
    final careerService = context.read<CareerService>();
    if (careerService.careers.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WelcomeDialog(
          onConfirm: (name, balance) {
            careerService.createCareer(name, balance);
            Navigator.of(context).pop();
            _showTabHint();
            _checkDisclaimer();
          },
        ),
      );
    } else {
      _checkDisclaimer();
    }
  }

  void _checkDisclaimer() {
    if (_disclaimerShown) return;
    _disclaimerShown = true;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RiskDisclaimerDialog(),
    );
  }

  void _showTabHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('👆 从这里探索 A 股市场'),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tradeSelection.removeListener(_onTradeSelectionChanged);
    super.dispose();
  }

  void _onTradeSelectionChanged() {
    // With AppShell, navigation is internal. The AppShell manages its own index.
    // For now, cross-tab navigation is still handled by TradeSelectionService listener in TradePage.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.initialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '数据正在路上... 🚀',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        AppShell(
          pages: _pages,
          labels: _labels,
          icons: _icons,
          activeIcons: _activeIcons,
        ),
        // Guest banner overlay (only on mobile where there's no sidebar user card)
        if (!auth.isLoggedIn)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GuestBanner(),
          ),
        // Achievement unlock toast
        Consumer<AchievementService>(
          builder: (context, service, _) {
            if (service.justUnlocked != null) {
              final a = service.achievements
                  .firstWhere((a) => a.id == service.justUnlocked);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    title: Text('${a.emoji} 成就解锁！',
                        style: const TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.bold)),
                    content: Text('${a.name}\n${a.description}',
                        style: const TextStyle(color: AppColors.textPrimary)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          service.clearJustUnlocked();
                        },
                        child: const Text('太棒了！',
                            style: TextStyle(color: AppColors.gold)),
                      ),
                    ],
                  ),
                );
              });
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/app/main_tabs_page.dart`
Expected: No errors (may have unused import warnings — OK for now).

- [ ] **Step 3: Commit**

```bash
git add lib/app/main_tabs_page.dart
git commit -m "refactor(ui): replace bottom nav shell with responsive AppShell"
```

---

### Task 6: Update market page to web grid layout + sentiment strip

**Files:**
- Modify: `lib/presentation/pages/market/market_page.dart`

Note: This task only updates the market page layout for web grid view. The SentimentStrip widget itself is created in Task 8.

- [ ] **Step 1: Wrap stock list in a responsive grid**

In `_buildStockListView` (line 428), replace the `ListView.builder` with a `LayoutBuilder` that uses a grid on wide screens:

```dart
Widget _buildStockListView(List<StockQuote> quotes, {bool showStar = false}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 700;
      if (isWide) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 60),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quotes.map((q) => SizedBox(
              width: (constraints.maxWidth - 20) / 2,
              child: _buildStockCard(q, showStar: showStar),
            )).toList(),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 60),
        itemCount: quotes.length,
        itemBuilder: (context, i) => _buildStockCard(quotes[i], showStar: showStar),
      );
    },
  );
}
```

- [ ] **Step 2: Add market sentiment strip placeholder at top of market page**

In `_MarketExplorerWidgetState.build()`, add a sentiment strip between `_buildHeader` and `_buildMarketSelector`:

```dart
// After _buildHeader(context), before _buildMarketSelector():
_MarketSentimentStrip(aShare: aShare),
```

Add this private widget at the bottom of the file (as a simple placeholder until Task 8):

```dart
class _MarketSentimentStrip extends StatelessWidget {
  const _MarketSentimentStrip({required this.aShare});
  final AShareService aShare;

  @override
  Widget build(BuildContext context) {
    final quotes = aShare.quotes;
    if (quotes.isEmpty) return const SizedBox.shrink();

    // Compute average absolute change
    double totalAbs = 0;
    for (final q in quotes) {
      totalAbs += q.changePct.abs();
    }
    final avgVolatility = quotes.isNotEmpty ? totalAbs / quotes.length : 0.0;

    String emoji;
    String label;
    String hint;
    Color bgColor;
    Color barColor;

    if (avgVolatility < 0.5) {
      emoji = '🧘';
      label = '佛系';
      hint = '市场风平浪静，适合慢慢研究';
      bgColor = AppColors.emotionZenBg;
      barColor = AppColors.emotionZen;
    } else if (avgVolatility < 2.0) {
      emoji = '🍿';
      label = '吃瓜看戏';
      hint = '小幅波动，市场正在寻找方向';
      bgColor = AppColors.emotionPopcornBg;
      barColor = AppColors.emotionPopcorn;
    } else {
      emoji = '🔥';
      label = '上头';
      hint = '波动较大，多看少动，注意风险';
      bgColor = AppColors.emotionFireBg;
      barColor = AppColors.emotionFire;
    }

    // Scale to 0..1 bar width (assuming max volatility ~5%)
    final barFraction = (avgVolatility / 5.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: barColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日市场情绪：$label',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '±${avgVolatility.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: barFraction,
                      minHeight: 6,
                      backgroundColor: AppColors.goldBg,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update empty state copy**

In `_emptyState`, update the text to use `AppText` warm copy constants.

- [ ] **Step 4: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/pages/market/market_page.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/market/market_page.dart
git commit -m "feat(ui): add market sentiment strip + responsive grid to market page"
```

---

### Task 7: Update assets page to two-column web layout

**Files:**
- Modify: `lib/presentation/pages/assets/assets_page.dart`

- [ ] **Step 1: Wrap content in LayoutBuilder for responsive two-column layout**

Replace the `ColoredBox > SafeArea > CustomScrollView` structure with a `LayoutBuilder` that switches between single-column (mobile) and two-column (desktop) layouts:

```dart
@override
Widget build(BuildContext context) {
  final aShare = context.watch<AShareService>();
  final portfolio = context.watch<PortfolioService>();
  final careerService = context.watch<CareerService>();
  final activeCareer = careerService.activeCareer;

  // ... (keep all data computation: priceMap, holdings, totalValue, todayPnl, allocations)

  return ColoredBox(
    color: AppColors.background,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          if (isWide) {
            return _buildWideLayout(
              context, totalValue, todayPnl, activeCareer,
              holdings, allocations, portfolio,
            );
          }
          return _buildMobileLayout(
            context, totalValue, todayPnl, activeCareer,
            holdings, allocations, portfolio,
          );
        },
      ),
    ),
  );
}
```

- [ ] **Step 2: Implement _buildWideLayout**

```dart
Widget _buildWideLayout(
  BuildContext context,
  double totalValue,
  double todayPnl,
  Career? activeCareer,
  List<_DisplayHolding> holdings,
  List<_DisplayAllocation> allocations,
  PortfolioService portfolio,
) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: total + PnL + holdings
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text('下午好 ☀️',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('总资产 (RMB)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDark],
                ).createShader(bounds),
                child: Text(
                  _formatRmb(totalValue),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text('估值以人民币计价',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 20),
              // Gain/loss row
              if (activeCareer != null)
                GainLossCard(career: activeCareer, todayPnl: todayPnl,
                  upColor: AppColors.up, downColor: AppColors.down),
              const SizedBox(height: 16),
              // Share button
              if (activeCareer != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final auth = context.read<AuthService>();
                      final cs = context.read<CareerService>();
                      final ac = cs.activeCareer;
                      if (ac != null) {
                        sharePerformanceCard(context, ac, auth.username ?? '交易员');
                      }
                    },
                    icon: const Icon(Icons.share, color: AppColors.gold),
                    label: const Text('📤 分享战绩',
                      style: TextStyle(color: AppColors.gold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Holdings header
              if (holdings.isNotEmpty)
                const Text('📦 持仓',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 10),
              // Holdings list
              ...holdings.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HoldingTile(holding: h),
              )),
              // Empty state
              if (holdings.isEmpty && portfolio.usdtBalance <= 0)
                _buildEmptyState(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column: emotion + allocation
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Emotion card
              _buildEmotionCard(context),
              const SizedBox(height: 14),
              // Equity curve
              if (activeCareer != null)
                EquityCurveChart(data: activeCareer.equityHistory),
              const SizedBox(height: 14),
              // Allocation
              if (allocations.isNotEmpty)
                _buildAllocationCard(allocations),
              // Trade history button
              if (activeCareer != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TradeHistoryPage()));
                    },
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text('交易记录',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add _buildEmotionCard helper**

```dart
Widget _buildEmotionCard(BuildContext context) {
  return Consumer<TradeHistoryService>(
    builder: (context, tradeHistory, _) {
      final recentTrades = tradeHistory.records
          .where((r) => r.createdAt.isAfter(
              DateTime.now().subtract(const Duration(days: 7))))
          .length;
      final emoji = recentTrades <= 1 ? '🧘' : recentTrades <= 5 ? '🍿' : '🔥';
      final label = recentTrades <= 1 ? '佛系' : recentTrades <= 5 ? '吃瓜' : '上头';
      final hint = recentTrades <= 1
          ? '淡定持有，心如止水'
          : recentTrades <= 5
              ? '观望中，吃瓜看戏'
              : AppText.highFrequency(recentTrades.toString());
      final barFraction = (recentTrades / 15.0).clamp(0.0, 1.0);
      final barColor = recentTrades <= 1
          ? AppColors.emotionZen
          : recentTrades <= 5
              ? AppColors.emotionPopcorn
              : AppColors.emotionFire;

      return Container(
        padding: const EdgeInsets.all(AppDimens.paddingCard),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surface, Color(0xFFFFF8EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.goldBorder, width: 1.5),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text('交易$label',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              ],
            ),
            const SizedBox(height: 8),
            Text(hint,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: barFraction,
                minHeight: 6,
                backgroundColor: AppColors.goldBg,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 4: Add _buildAllocationCard helper**

```dart
Widget _buildAllocationCard(List<_DisplayAllocation> allocations) {
  return Container(
    padding: const EdgeInsets.all(AppDimens.paddingCard),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 资产分布',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          )),
        const SizedBox(height: 12),
        ...allocations.map((a) {
          final pct = (a.percent * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(a.symbol,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    Text('$pct%',
                      style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: a.percent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.goldBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}
```

- [ ] **Step 5: Keep _buildMobileLayout as the original CustomScrollView**

Move the existing `CustomScrollView` code into `_buildMobileLayout` (no functional changes, just structural).

- [ ] **Step 6: Update _HoldingTile to use new colors and shadow**

Update the card decoration:
```dart
decoration: BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
  border: Border.all(color: AppColors.border, width: 1.5),
  boxShadow: AppShadows.card,
),
```

- [ ] **Step 7: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/pages/assets/assets_page.dart`
Expected: No errors.

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/pages/assets/assets_page.dart
git commit -m "feat(ui): two-column responsive assets page with emotion card"
```

---

### Task 8: Update trade page — centered form layout

**Files:**
- Modify: `lib/presentation/pages/trade/trade_page.dart`

- [ ] **Step 1: Wrap trade form in a constrained centered container for desktop**

In `_TradePageState.build()`, wrap the `ColoredBox` content in a `LayoutBuilder` that centers the form on wide screens:

```dart
return ListenableBuilder(
  listenable: _c,
  builder: (context, _) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ConfettiOverlay(
          play: _showConfetti,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return Center(
                child: SizedBox(
                  width: isWide ? 480 : double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ... (existing content exactly as before)
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  },
);
```

- [ ] **Step 2: Update SnackBar copy and colors**

Update the success SnackBar:
```dart
ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      content: Row(
        children: [
          const Icon(Icons.task_alt_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppText.tradeSuccess,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
```

Update error SnackBar:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(result.message),
    backgroundColor: AppColors.down,
    behavior: SnackBarBehavior.floating,
  ),
);
```

- [ ] **Step 3: Update TipBubble text**

In the `TipBubble` widget usage, update the default text to use `AppText.newbieTip`.

- [ ] **Step 4: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/pages/trade/trade_page.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/trade/trade_page.dart
git commit -m "feat(ui): centered trade form layout + warm SnackBar copy"
```

---

### Task 9: Update profile page — adapt to sidebar context

**Files:**
- Modify: `lib/presentation/pages/profile/profile_page.dart`

- [ ] **Step 1: Update achievement section to use padded card style**

Update `_buildAchievementSection` to use new card styling:

```dart
Widget _buildAchievementSection(BuildContext context) {
  final achievementService = context.watch<AchievementService>();
  final achievements = achievementService.achievements;

  return Container(
    padding: const EdgeInsets.all(AppDimens.paddingCard),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🏅 成就勋章', style: TextStyle(
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
                    color: unlocked
                        ? AppColors.goldBg
                        : AppColors.unselectedBg,
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
                Text(a.name, style: TextStyle(
                  fontSize: 10,
                  color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                )),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Update menu card styling**

Update `_menuCard`:
```dart
Widget _menuCard(BuildContext context, List<Widget> items) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: AppShadows.card,
    ),
    child: Column(children: items),
  );
}
```

- [ ] **Step 3: Remove Scaffold (AppShell already provides it)**

Since `ProfilePage` is now inside `AppShell`'s `IndexedStack`, remove the outer `Scaffold` wrapper and return just the `ListView` directly. The background color is inherited from the parent.

- [ ] **Step 4: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/pages/profile/profile_page.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/profile/profile_page.dart
git commit -m "feat(ui): update profile page with warm card styling"
```

---

### Task 10: Update remaining pages — leaderboard, battle, tutorial, stock detail

**Files:**
- Modify: `lib/presentation/pages/leaderboard/leaderboard_page.dart`
- Modify: `lib/presentation/pages/battle/battle_list_page.dart`
- Modify: `lib/presentation/pages/market/stock_detail_page.dart`
- Modify: `lib/presentation/pages/tutorial/tutorial_page.dart`

- [ ] **Step 1: Update leaderboard_page.dart — replace Scaffold with direct content**

Remove the outer `Scaffold` and `AppBar`. Since page now lives inside AppShell's IndexedStack, return just a `Column` with the body content. Add a header text at top:

```dart
@override
Widget build(BuildContext context) {
  // ...
  return Column(
    children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
        child: Row(
          children: [
            const Text('🏆 排行榜',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
          ],
        ),
      ),
      // ... existing body content
    ],
  );
}
```

- [ ] **Step 2: Update battle_list_page.dart — same treatment**

Remove Scaffold + AppBar, replace with a Column with header text `'⚔️ 好友对战'`.

- [ ] **Step 3: Update stock_detail_page.dart — keep Scaffold (it's a pushed route)**

StockDetailPage is a full-screen push route, so it keeps its Scaffold. Just ensure it uses the new `AppColors.*` tokens (already done in Task 3).

- [ ] **Step 4: Update tutorial_page.dart — keep Scaffold (pushed route)**

Same — it's a pushed route, so keep Scaffold. Update colors to use `AppColors.*` tokens.

- [ ] **Step 5: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/pages/`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/
git commit -m "feat(ui): adapt sub-pages to sidebar layout + warm tokens"
```

---

### Task 11: Market Sentiment Service

**Files:**
- Create: `lib/domain/services/market_sentiment_service.dart`

- [ ] **Step 1: Create MarketSentimentService**

Create `lib/domain/services/market_sentiment_service.dart`:

```dart
import 'package:flutter/foundation.dart';

enum SentimentLevel { zen, popcorn, fire }

class MarketSentiment {
  final SentimentLevel level;
  final double avgVolatility;
  final String emoji;
  final String label;
  final String hint;

  const MarketSentiment({
    required this.level,
    required this.avgVolatility,
    required this.emoji,
    required this.label,
    required this.hint,
  });
}

class MarketSentimentService extends ChangeNotifier {
  MarketSentiment _marketSentiment = const MarketSentiment(
    level: SentimentLevel.popcorn,
    avgVolatility: 0.0,
    emoji: '🍿',
    label: '吃瓜看戏',
    hint: '加载中...',
  );

  MarketSentiment get marketSentiment => _marketSentiment;

  /// Compute market-level sentiment from a list of absolute change percentages.
  void computeMarket(List<double> absChanges) {
    if (absChanges.isEmpty) return;

    final avg = absChanges.reduce((a, b) => a + b) / absChanges.length;

    final SentimentLevel level;
    final String emoji;
    final String label;
    final String hint;

    if (avg < 0.5) {
      level = SentimentLevel.zen;
      emoji = '🧘';
      label = '佛系';
      hint = '市场风平浪静，适合慢慢研究';
    } else if (avg < 2.0) {
      level = SentimentLevel.popcorn;
      emoji = '🍿';
      label = '吃瓜看戏';
      hint = '小幅波动，市场正在寻找方向';
    } else {
      level = SentimentLevel.fire;
      emoji = '🔥';
      label = '上头';
      hint = '波动较大，多看少动，注意风险';
    }

    final newSentiment = MarketSentiment(
      level: level,
      avgVolatility: avg,
      emoji: emoji,
      label: label,
      hint: hint,
    );

    if (newSentiment.level != _marketSentiment.level ||
        (newSentiment.avgVolatility - _marketSentiment.avgVolatility).abs() > 0.1) {
      _marketSentiment = newSentiment;
      notifyListeners();
    }
  }

  /// Compute user-level sentiment from recent trade count.
  SentimentLevel userSentiment(int recentTradeCount) {
    if (recentTradeCount <= 1) return SentimentLevel.zen;
    if (recentTradeCount <= 5) return SentimentLevel.popcorn;
    return SentimentLevel.fire;
  }
}
```

- [ ] **Step 2: Register MarketSentimentService in main.dart**

In `lib/main.dart`, add:
```dart
ChangeNotifierProvider(create: (_) => MarketSentimentService()),
```

- [ ] **Step 3: Wire sentiment computation in market page**

In `MarketExplorerWidget`, after receiving quotes from `AShareService`, trigger sentiment computation:

```dart
// In build() or a listener:
final sentimentService = context.read<MarketSentimentService>();
final absChanges = aShare.quotes.map((q) => q.changePct.abs()).toList();
sentimentService.computeMarket(absChanges);
```

Note: This should be guarded to avoid calling `computeMarket` on every build. Use a `addPostFrameCallback` or a dedicated listener on `AShareService`.

- [ ] **Step 4: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/domain/services/market_sentiment_service.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/market_sentiment_service.dart lib/main.dart
git commit -m "feat: add MarketSentimentService for market + user emotion computation"
```

---

### Task 12: Copy upgrade — warm encouraging text across all pages

**Files:**
- Modify: `lib/presentation/pages/market/market_page.dart`
- Modify: `lib/presentation/pages/assets/assets_page.dart`
- Modify: `lib/presentation/pages/trade/trade_page.dart`
- Modify: `lib/presentation/pages/profile/profile_page.dart`
- Modify: `lib/presentation/pages/leaderboard/leaderboard_page.dart`
- Modify: `lib/presentation/pages/battle/battle_list_page.dart`
- Modify: `lib/presentation/widgets/guest_banner.dart`

- [ ] **Step 1: Update market_page.dart empty states**

Replace `_emptyState` calls with the new AppText constants:
```dart
_emptyState(AppText.emptyWatchlistTitle, AppText.emptyWatchlist)
_emptyState(AppText.noMatchResult, AppText.tryOtherSearch)
```

- [ ] **Step 2: Update assets_page.dart empty state**

Replace '暂无持仓' with `AppText.emptyHoldingsTitle` and the subtitle with `AppText.emptyHoldings`.

- [ ] **Step 3: Update trade_page.dart error messages**

Update the balance-insufficient check in `TradeFormController` to use `AppText.balanceInsufficient`.

- [ ] **Step 4: Update leaderboard + battle guest lock copy**

Replace '登录后查看排行榜' → '登录后查看排行榜，与全球交易者一较高下 🏆'
Replace '登录后参与好友对战' → '登录后参与好友对战，邀请好友一决高下 ⚔️'

- [ ] **Step 5: Update loading states**

Replace `'正在加载...'` with `AppText.loadingData` in all pages.
Replace error retry text with `AppText.networkError`.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/
git commit -m "feat(ui): upgrade all copy to warm encouraging tone"
```

---

### Task 13: Add hover micro-interactions with MouseRegion

**Files:**
- Modify: `lib/presentation/pages/market/market_page.dart` (stock cards)
- Modify: `lib/presentation/pages/assets/assets_page.dart` (holding cards)
- Create: `lib/presentation/widgets/hover_card.dart`

- [ ] **Step 1: Create HoverCard wrapper widget**

Create `lib/presentation/widgets/hover_card.dart`:

```dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

/// Card wrapper that adds hover lift + golden border effect on web.
class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final double? borderRadius;
  final VoidCallback? onTap;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppDimens.radiusLg;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _hovered
              ? (Matrix4.identity()..translate(0, -2))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _hovered ? AppColors.gold : AppColors.border,
              width: 1.5,
            ),
            boxShadow: _hovered ? AppShadows.hover : AppShadows.card,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wrap stock cards in HoverCard**

In `_buildStockCard` in `market_page.dart`, wrap the card content:

```dart
return HoverCard(
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => StockDetailPage(quote: row))),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      // ... existing card content
    ),
  ),
);
```

Remove the outer `Container` decoration and `GestureDetector` — `HoverCard` provides both.

- [ ] **Step 3: Wrap holding cards in HoverCard**

In `_HoldingTile` in `assets_page.dart`, wrap with `HoverCard`.

- [ ] **Step 4: Add hover to sidebar nav items**

The `_NavItem` in `app_shell.dart` already uses `InkWell` — add `MouseRegion` to show pointer cursor on web:

```dart
return MouseRegion(
  cursor: SystemMouseCursors.click,
  child: Material(...),
);
```

- [ ] **Step 5: Verify compilation**

Run: `cd D:/DarkTradeApp && dart analyze lib/presentation/widgets/hover_card.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/hover_card.dart lib/presentation/pages/market/market_page.dart lib/presentation/pages/assets/assets_page.dart lib/presentation/widgets/app_shell.dart
git commit -m "feat(ui): add HoverCard with lift + golden border micro-interactions"
```

---

### Task 14: Final integration — register services, test, and polish

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add MarketSentimentService to main.dart provider list**

In `lib/main.dart`, add:
```dart
ChangeNotifierProvider(create: (_) => MarketSentimentService()),
```

to the `MultiProvider` list.

- [ ] **Step 2: Run full static analysis**

Run: `cd D:/DarkTradeApp && dart analyze lib/`
Expected: No errors.

- [ ] **Step 3: Run the app and verify**

Run: `cd D:/DarkTradeApp && flutter run -d chrome`
Check:
1. Sidebar renders on desktop (>900px)
2. Bottom nav renders on mobile (<600px)
3. Market sentiment strip shows on market page
4. Emotion card shows on assets page
5. Cards have hover effects on desktop
6. All colors use warm new palette
7. Copy is warm and encouraging

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(ui): final integration — register MarketSentimentService"
```

- [ ] **Step 5: Create a summary commit of any remaining fixes**

```bash
git add -A
git commit -m "chore(ui): final warm redesign polish and cleanup"
```

---

## Implementation Order

Tasks must be executed sequentially in order (1 → 14). Each task depends on the previous one:

```
Phase 1 (Foundation):  Task 1 → Task 2 → Task 3
Phase 2 (Layout):      Task 4 → Task 5 → Task 6 → Task 7 → Task 8 → Task 9 → Task 10
Phase 3 (Sentiment):   Task 11
Phase 4 (Copy):        Task 12
Phase 5 (Animation):   Task 13
Finalize:              Task 14
```

---

## Total: 14 tasks, ~14 commits
