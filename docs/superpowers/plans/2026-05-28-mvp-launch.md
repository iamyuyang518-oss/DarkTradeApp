# DarkTrade MVP 发布实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 DarkTrade 从本地 Demo 升级为可发布的 A 股模拟交易平台（含 Supabase 账号系统 + 游客模式 + 新手引导 + 合规层）

**Architecture:** Provider 状态管理 + Repository 模式（HiveLocalRepo / SupabaseRemoteRepo）+ 三层结构（data/domain/presentation），仅保留 A 股行情

**Tech Stack:** Flutter Web · Provider · Hive · Supabase Flutter SDK · 东方财富 API（CORS 代理）· share_plus

**Spec:** `docs/superpowers/specs/2026-05-28-mvp-launch-design.md`

---

## File Map

```
lib/
├── main.dart                                    # MODIFY — 简化入口
├── app/
│   ├── app.dart                                # CREATE — MaterialApp + 主题
│   └── main_tabs_page.dart                     # MOVE from lib/app/main_tabs_page.dart
├── core/
│   ├── constants.dart                          # CREATE — 颜色/尺寸/文案常量
│   ├── theme.dart                              # CREATE — ThemeData (从 flutter_flow 迁移)
│   └── extensions.dart                         # CREATE — BuildContext 扩展
├── data/
│   ├── local/
│   │   ├── hive_service.dart                   # MOVE from lib/services/hive_service.dart
│   │   └── models/
│   │       ├── career.dart                     # MOVE from lib/models/career.dart
│   │       ├── career.g.dart                   # MOVE
│   │       ├── trade_record.dart               # MOVE from lib/models/trade_record.dart
│   │       └── trade_record.g.dart             # MOVE
│   ├── remote/
│   │   ├── supabase_client.dart                # CREATE
│   │   └── a_share_api.dart                    # MOVE from lib/services/a_share_service.dart (API部分)
│   └── repositories/
│       ├── career_repository.dart              # CREATE
│       └── trade_history_repository.dart       # CREATE
├── domain/
│   ├── services/
│   │   ├── auth_service.dart                   # CREATE
│   │   ├── market_data_service.dart            # MOVE from lib/services/market_data_service.dart
│   │   ├── a_share_service.dart                # MOVE (重构为ChangeNotifier包装)
│   │   ├── career_service.dart                 # MOVE + REFACTOR (依赖Repository)
│   │   ├── portfolio_service.dart              # MOVE
│   │   ├── trade_history_service.dart          # MOVE + REFACTOR (依赖Repository)
│   │   └── trade_selection_service.dart        # MOVE
│   └── models/
│       └── stock_quote.dart                    # MOVE from market_data_service.dart
└── presentation/
    ├── pages/
    │   ├── market/
    │   │   ├── market_page.dart                # MOVE + REFACTOR (仅A股, 去TabBar)
    │   │   ├── widgets/
    │   │   │   ├── stock_row_widget.dart       # MOVE
    │   │   │   ├── category_chip_widget.dart   # MOVE
    │   │   │   └── sentiment_dashboard.dart    # CREATE
    │   │   └── stock_detail_page.dart          # MOVE
    │   ├── assets/
    │   │   ├── assets_page.dart                # MOVE + REFACTOR
    │   │   └── widgets/
    │   │       ├── gain_loss_card.dart         # MOVE
    │   │       ├── equity_curve_chart.dart     # MOVE
    │   │       └── career_selector.dart        # MOVE
    │   ├── trade/
    │   │   ├── trade_page.dart                 # MOVE from lib/presentation/pages/trade/trade_page.dart
    │   │   ├── logic/
    │   │   │   └── trade_form_controller.dart  # MOVE
    │   │   └── widgets/                        # MOVE all 7 widgets
    │   ├── profile/
    │   │   ├── profile_page.dart               # MOVE + REFACTOR
    │   │   ├── trade_history_page.dart          # MOVE
    │   │   └── career_management_sheet.dart    # MOVE
    │   └── tutorial/
    │       └── tutorial_page.dart              # CREATE (P1 content, P0 skeleton)
    └── widgets/
        ├── confetti_overlay.dart               # MOVE
        ├── kline_chart.dart                    # MOVE
        ├── guest_banner.dart                   # MOVE
        ├── tip_bubble.dart                     # CREATE
        └── risk_disclaimer.dart                # CREATE

DELETE:
  lib/flutter_flow/ (entire directory)
  lib/trade_page.dart (duplicate)
  lib/pages/trade_execution_widget.dart (obsolete)
  lib/services/live_market_service.dart (crypto, removed)
  lib/services/us_stock_service.dart (removed)
  lib/components/ (moved under presentation)
  lib/index.dart
```

---

### Task 1: 创建新目录结构

**Files:**
- Create: 所有空目录

- [ ] **Step 1: 创建新目录**

```bash
cd D:/DarkTradeApp
mkdir -p lib/app
mkdir -p lib/core
mkdir -p lib/data/local/models
mkdir -p lib/data/remote
mkdir -p lib/data/repositories
mkdir -p lib/domain/services
mkdir -p lib/domain/models
mkdir -p lib/presentation/pages/market/widgets
mkdir -p lib/presentation/pages/assets/widgets
mkdir -p lib/presentation/pages/trade/logic
mkdir -p lib/presentation/pages/trade/widgets
mkdir -p lib/presentation/pages/profile
mkdir -p lib/presentation/pages/tutorial
mkdir -p lib/presentation/widgets
```

- [ ] **Step 2: 验证目录创建成功**

```bash
ls -d lib/core lib/data/local lib/data/remote lib/data/repositories lib/domain/services lib/presentation/pages/market lib/presentation/pages/tutorial
```

- [ ] **Step 3: Commit**

```bash
git add lib/app lib/core lib/data lib/domain lib/presentation
git commit -m "chore: create new directory structure for MVP restructure"
```

---

### Task 2: 提取核心常量与主题

**Files:**
- Create: `lib/core/constants.dart`
- Create: `lib/core/theme.dart`
- Create: `lib/core/extensions.dart`
- Read: `lib/flutter_flow/flutter_flow_theme.dart` (reference)

- [ ] **Step 1: 创建 constants.dart**

```dart
// lib/core/constants.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // 背景与表面
  static const Color background = Color(0xFFFFFBF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8DCC8);

  // 强调色
  static const Color gold = Color(0xFFD4A853);

  // 文字
  static const Color textPrimary = Color(0xFF3D3025);
  static const Color textSecondary = Color(0xFFA09078);

  // 涨跌
  static const Color up = Color(0xFF43A047);
  static const Color upBg = Color(0xFFE8F5E9);
  static const Color down = Color(0xFFE57373);
  static const Color downBg = Color(0xFFFFF0F0);

  // 其他
  static const Color unselectedBg = Color(0xFFF5EDE0);
  static const Color unselectedText = Color(0xFFB8976A);
  static const Color navBg = Color(0xFFFFFBF5);
  static const Color navSelected = Color(0xFFD4A853);
  static const Color navUnselected = Color(0xFFA09078);
}

abstract class AppDimens {
  AppDimens._();
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double paddingPage = 16.0;
  static const double paddingCard = 14.0;
}

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
}
```

- [ ] **Step 2: 创建 theme.dart**

```dart
// lib/core/theme.dart
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.unselectedBg,
        selectedColor: AppColors.gold,
        labelStyle: const TextStyle(color: AppColors.unselectedText),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        side: BorderSide.none,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 extensions.dart**

```dart
// lib/core/extensions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ContextExt on BuildContext {
  T read<T>() => Provider.of<T>(this, listen: false);
  T watch<T>() => Provider.of<T>(this, listen: true);
  MediaQueryData get mq => MediaQuery.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants.dart lib/core/theme.dart lib/core/extensions.dart
git commit -m "feat: add core constants, theme, and context extensions"
```

---

### Task 3: 移动 Hive 数据模型至 data/local/models

**Files:**
- Move: `lib/models/career.dart` → `lib/data/local/models/career.dart`
- Move: `lib/models/career.g.dart` → `lib/data/local/models/career.g.dart`
- Move: `lib/models/trade_record.dart` → `lib/data/local/models/trade_record.dart`
- Move: `lib/models/trade_record.g.dart` → `lib/data/local/models/trade_record.g.dart`
- Move: `lib/services/hive_service.dart` → `lib/data/local/hive_service.dart`

- [ ] **Step 1: 移动文件**

```bash
cd D:/DarkTradeApp
mv lib/models/career.dart lib/data/local/models/career.dart
mv lib/models/career.g.dart lib/data/local/models/career.g.dart
mv lib/models/trade_record.dart lib/data/local/models/trade_record.dart
mv lib/models/trade_record.g.dart lib/data/local/models/trade_record.g.dart
mv lib/services/hive_service.dart lib/data/local/hive_service.dart
```

- [ ] **Step 2: 更新所有引用这些文件的 import 路径**

需要更新 import 路径的文件（通过 grep 确定）：
```bash
cd D:/DarkTradeApp
grep -rn "package:dark_trade_app/models/" lib/ --include="*.dart"
grep -rn "package:dark_trade_app/services/hive_service" lib/ --include="*.dart"
```

使用 Edit 工具逐个更新 import：
- `package:dark_trade_app/models/career.dart` → `package:dark_trade_app/data/local/models/career.dart`
- `package:dark_trade_app/models/trade_record.dart` → `package:dark_trade_app/data/local/models/trade_record.dart`
- `package:dark_trade_app/services/hive_service.dart` → `package:dark_trade_app/data/local/hive_service.dart`

- [ ] **Step 3: 删除空目录**

```bash
rmdir lib/models 2>/dev/null; echo "done"
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: move Hive models to data/local/models, HiveService to data/local"
```

---

### Task 4: 移动服务层文件至 domain/services

**Files to move:**
- `lib/services/market_data_service.dart` → `lib/domain/services/market_data_service.dart`
- `lib/services/a_share_service.dart` → `lib/domain/services/a_share_service.dart`
- `lib/services/career_service.dart` → `lib/domain/services/career_service.dart`
- `lib/services/portfolio_service.dart` → `lib/domain/services/portfolio_service.dart`
- `lib/services/trade_history_service.dart` → `lib/domain/services/trade_history_service.dart`
- `lib/services/trade_selection_service.dart` → `lib/domain/services/trade_selection_service.dart`

- [ ] **Step 1: 移动服务文件**

```bash
cd D:/DarkTradeApp
mv lib/services/market_data_service.dart lib/domain/services/market_data_service.dart
mv lib/services/a_share_service.dart lib/domain/services/a_share_service.dart
mv lib/services/career_service.dart lib/domain/services/career_service.dart
mv lib/services/portfolio_service.dart lib/domain/services/portfolio_service.dart
mv lib/services/trade_history_service.dart lib/domain/services/trade_history_service.dart
mv lib/services/trade_selection_service.dart lib/domain/services/trade_selection_service.dart
```

- [ ] **Step 2: 批量更新所有引用路径**

```bash
cd D:/DarkTradeApp
find lib/ -name "*.dart" -exec sed -i 's|package:dark_trade_app/services/market_data_service|package:dark_trade_app/domain/services/market_data_service|g' {} +
find lib/ -name "*.dart" -exec sed -i 's|package:dark_trade_app/services/a_share_service|package:dark_trade_app/domain/services/a_share_service|g' {} +
find lib/ -name "*.dart" -exec sed -i 's|package:dark_trade_app/services/career_service|package:dark_trade_app/domain/services/career_service|g' {} +
find lib/ -name "*.dart" -exec sed -i 's|package:dark_trade_app/services/portfolio_service|package:dark_trade_app/domain/services/portfolio_service|g' {} +
find lib/ -name "*.dart" -exec sed -i 's|package:dark_trade_app/services/trade_history_service|package:dark_trade_app/domain/services/trade_history_service|g' {} +
find lib/ -name "*.dart" -exec sed -i 's|package:dark_trade_app/services/trade_selection_service|package:dark_trade_app/domain/services/trade_selection_service|g' {} +
```

- [ ] **Step 3: 删除空的 services 目录**

```bash
rmdir lib/services 2>/dev/null; echo "done"
```

- [ ] **Step 4: 验证编译**

```bash
cd D:/DarkTradeApp && flutter analyze 2>&1 | head -20
```

Expected: no errors (only existing info/warnings).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move services to domain/services, update all import paths"
```

---

### Task 5: 移动 UI 文件至 presentation

**Files to move:**
- `lib/app/main_tabs_page.dart` → `lib/app/main_tabs_page.dart` (stay)
- `lib/market_explorer.dart` → `lib/presentation/pages/market/market_page.dart`
- `lib/assets_page.dart` → `lib/presentation/pages/assets/assets_page.dart`
- `lib/presentation/pages/trade/trade_page.dart` → `lib/presentation/pages/trade/trade_page.dart` (stay)
- `lib/profile_page.dart` → `lib/presentation/pages/profile/profile_page.dart`
- `lib/pages/stock_detail_page.dart` → `lib/presentation/pages/market/stock_detail_page.dart`
- `lib/pages/career_management_sheet.dart` → `lib/presentation/pages/profile/career_management_sheet.dart`
- `lib/pages/trade_history_page.dart` → `lib/presentation/pages/profile/trade_history_page.dart`
- `lib/components/stock_row/stock_row_widget.dart` → `lib/presentation/pages/market/widgets/stock_row_widget.dart`
- `lib/components/category_chip/category_chip_widget.dart` → `lib/presentation/pages/market/widgets/category_chip_widget.dart`
- `lib/components/text_field/text_field_widget.dart` → `lib/presentation/widgets/text_field_widget.dart`
- `lib/widgets/` → `lib/presentation/widgets/`
- `lib/presentation/pages/trade/widgets/` → (stay)
- `lib/presentation/pages/trade/logic/` → (stay)

- [ ] **Step 1: 移动页面文件**

```bash
cd D:/DarkTradeApp
mv lib/market_explorer.dart lib/presentation/pages/market/market_page.dart
mv lib/assets_page.dart lib/presentation/pages/assets/assets_page.dart
mv lib/profile_page.dart lib/presentation/pages/profile/profile_page.dart
mv lib/pages/stock_detail_page.dart lib/presentation/pages/market/stock_detail_page.dart
mv lib/pages/career_management_sheet.dart lib/presentation/pages/profile/career_management_sheet.dart
mv lib/pages/trade_history_page.dart lib/presentation/pages/profile/trade_history_page.dart
```

- [ ] **Step 2: 移动组件文件**

```bash
cd D:/DarkTradeApp
mv lib/components/stock_row/stock_row_widget.dart lib/presentation/pages/market/widgets/stock_row_widget.dart
mv lib/components/category_chip/category_chip_widget.dart lib/presentation/pages/market/widgets/category_chip_widget.dart
mv lib/components/text_field/text_field_widget.dart lib/presentation/widgets/text_field_widget.dart

# 移动 widgets 目录下所有文件到 presentation/widgets
cp lib/widgets/*.dart lib/presentation/widgets/
rm -rf lib/widgets lib/components lib/pages
```

- [ ] **Step 3: 更新所有 import 路径**

用 grep 查找所有需要更新的导入路径并逐一更新：
```bash
cd D:/DarkTradeApp
# 列出所有需要更新的 import
grep -rn "package:dark_trade_app/market_explorer" lib/ || echo "none"
grep -rn "package:dark_trade_app/assets_page" lib/ || echo "none"
grep -rn "package:dark_trade_app/profile_page" lib/ || echo "none"
grep -rn "package:dark_trade_app/pages/" lib/ || echo "none"
grep -rn "package:dark_trade_app/components/" lib/ || echo "none"
grep -rn "package:dark_trade_app/widgets/" lib/ || echo "none"
```

更新 import 路径（使用 Edit 工具逐个修改每个文件）：
- `package:dark_trade_app/market_explorer.dart` → `package:dark_trade_app/presentation/pages/market/market_page.dart`
- `package:dark_trade_app/assets_page.dart` → `package:dark_trade_app/presentation/pages/assets/assets_page.dart`
- `package:dark_trade_app/profile_page.dart` → `package:dark_trade_app/presentation/pages/profile/profile_page.dart`
- `package:dark_trade_app/pages/stock_detail_page.dart` → `package:dark_trade_app/presentation/pages/market/stock_detail_page.dart`
- `package:dark_trade_app/pages/career_management_sheet.dart` → `package:dark_trade_app/presentation/pages/profile/career_management_sheet.dart`
- `package:dark_trade_app/pages/trade_history_page.dart` → `package:dark_trade_app/presentation/pages/profile/trade_history_page.dart`
- `package:dark_trade_app/components/...` → `package:dark_trade_app/presentation/pages/market/widgets/...`
- `package:dark_trade_app/widgets/...` → `package:dark_trade_app/presentation/widgets/...`

- [ ] **Step 4: 验证编译**

```bash
cd D:/DarkTradeApp && flutter analyze 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move all UI files to presentation/, reorganize pages and widgets"
```

---

### Task 6: 删除废弃代码（flutter_flow, 加密货币, 美股, 重复文件）

**Files:**
- Delete: `lib/flutter_flow/` (所有文件)
- Delete: `lib/trade_page.dart`
- Delete: `lib/pages/trade_execution_widget.dart` (如果还存在)
- Delete: `lib/services/live_market_service.dart` (如果还存在)
- Delete: `lib/services/us_stock_service.dart` (如果还存在)
- Delete: `lib/index.dart`

- [ ] **Step 1: 删除废弃目录和文件**

```bash
cd D:/DarkTradeApp
rm -rf lib/flutter_flow
rm -f lib/trade_page.dart
rm -f lib/pages/trade_execution_widget.dart
rm -f lib/services/live_market_service.dart
rm -f lib/services/us_stock_service.dart
rm -f lib/index.dart
```

- [ ] **Step 2: 更新 main.dart，移除废弃 import 和 Provider**

Read `lib/main.dart`，然后重写为：

```dart
// lib/main.dart
import 'package:dark_trade_app/app/app.dart';
import 'package:dark_trade_app/data/local/hive_service.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  final aShare = AShareService()..start();
  final portfolio = PortfolioService()..seedDemo();
  final tradeSelection = TradeSelectionService();
  final careerService = CareerService();
  final tradeHistory = TradeHistoryService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: aShare),
        ChangeNotifierProvider.value(value: portfolio),
        ChangeNotifierProvider.value(value: tradeSelection),
        ChangeNotifierProvider.value(value: careerService),
        ChangeNotifierProvider.value(value: tradeHistory),
      ],
      child: const DarkTradeApp(),
    ),
  );
}
```

- [ ] **Step 3: 创建 app.dart**

```dart
// lib/app/app.dart
import 'package:dark_trade_app/app/main_tabs_page.dart';
import 'package:dark_trade_app/core/theme.dart';
import 'package:flutter/material.dart';

class DarkTradeApp extends StatelessWidget {
  const DarkTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarkTrade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const MainTabsPage(),
    );
  }
}
```

- [ ] **Step 4: 更新 main_tabs_page.dart 的 import**

确保 `lib/app/main_tabs_page.dart` 中的 import 指向新的页面路径。

- [ ] **Step 5: 验证编译**

```bash
cd D:/DarkTradeApp && flutter analyze 2>&1 | tail -10
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: remove flutter_flow, crypto, US stocks, dead code; create app.dart"
```

---

### Task 7: 简化行情页 — 仅保留 A 股

**Files:**
- Modify: `lib/presentation/pages/market/market_page.dart`
- Modify: `lib/app/main_tabs_page.dart` (如引用 market_page)

- [ ] **Step 1: 重写 market_page.dart 为纯 A 股展示**

Read 当前 `lib/presentation/pages/market/market_page.dart`，然后重写为仅 A 股内容：

```dart
// lib/presentation/pages/market/market_page.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/presentation/pages/market/widgets/category_chip_widget.dart';
import 'package:dark_trade_app/presentation/pages/market/widgets/stock_row_widget.dart';
import 'package:dark_trade_app/presentation/widgets/guest_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AShareService>();
    final quotes = service.quotes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('行情', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '交易学院',
            onPressed: () {
              // TODO: navigate to tutorial page (P1)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const GuestBanner(),
          // 数据延迟标注
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              AppText.dataDelayNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // 情绪仪表盘 (P1 skeleton)
          // TODO: SentimentDashboard in P1
          // 分类 Chip
          // TODO: category chips in P1
          const SizedBox(height: 8),
          // 股票列表
          Expanded(
            child: quotes.isEmpty
                ? _buildEmptyState(context)
                : _buildStockList(context, quotes),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToTrade(context),
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.swap_horiz),
        label: const Text('快速交易'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final service = context.read<AShareService>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(service.lastError ?? '暂无行情数据', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => service.refresh(), child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildStockList(BuildContext context, List<dynamic> quotes) {
    return RefreshIndicator(
      onRefresh: () => context.read<AShareService>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return StockRowWidget(
            stockId: quote.id,
            symbol: quote.symbol,
            name: quote.name,
            price: quote.currentPrice,
            changePercent: quote.priceChangePercent24h,
            onTap: () => _navigateToDetail(context, quote),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, dynamic quote) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StockDetailPage(quote: quote),
    ));
  }

  void _navigateToTrade(BuildContext context) {
    // Navigate to trade tab or trade page
    // Use the existing trade page
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const TradePage(),
    ));
  }
}
```

注意：实际的 `StockRowWidget`、`StockDetailPage`、`TradePage` 的构造函数参数需对齐现有代码。此处为核心骨架，执行时需根据实际 API 微调。

- [ ] **Step 2: 运行分析，修复引用问题**

```bash
cd D:/DarkTradeApp && flutter analyze lib/presentation/pages/market/ 2>&1
```

修复所有报错。

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: simplify market page to A-share only, remove crypto and US stock tabs"
```

---

### Task 8: 创建 Repository 接口与实现

**Files:**
- Create: `lib/data/repositories/career_repository.dart`
- Create: `lib/data/repositories/trade_history_repository.dart`

- [ ] **Step 1: 创建 CareerRepository**

```dart
// lib/data/repositories/career_repository.dart
import 'package:dark_trade_app/data/local/models/career.dart';

abstract class CareerRepository {
  Future<List<Career>> loadCareers();
  Future<void> saveCareer(Career career);
  Future<void> deleteCareer(String id);
  Future<void> saveAllCareers(List<Career> careers);
  Future<List<Career>> migrateFromLocal(); // 游客数据导入时调用
}

class HiveCareerRepo implements CareerRepository {
  // 使用现有 HiveService 的逻辑
  // 具体实现从 CareerService 中迁移过来
  @override
  Future<List<Career>> loadCareers() async {
    // TODO: migrate from CareerService Hive logic
    throw UnimplementedError();
  }

  @override
  Future<void> saveCareer(Career career) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCareer(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveAllCareers(List<Career> careers) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Career>> migrateFromLocal() async {
    return loadCareers();
  }
}
```

- [ ] **Step 2: 创建 TradeHistoryRepository**

```dart
// lib/data/repositories/trade_history_repository.dart
import 'package:dark_trade_app/data/local/models/trade_record.dart';

abstract class TradeHistoryRepository {
  Future<List<TradeRecord>> loadRecords(String careerId);
  Future<void> saveRecord(TradeRecord record);
  Future<void> deleteRecord(String id);
  Future<void> saveAllRecords(List<TradeRecord> records);
  Future<List<TradeRecord>> migrateFromLocal(String careerId);
}

class HiveTradeHistoryRepo implements TradeHistoryRepository {
  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveRecord(TradeRecord record) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRecord(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async {
    return loadRecords(careerId);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/
git commit -m "feat: add CareerRepository and TradeHistoryRepository interfaces"
```

---

### Task 9: 实现 HiveLocalRepo（填充 HiveCareerRepo 和 HiveTradeHistoryRepo）

**Files:**
- Modify: `lib/data/repositories/career_repository.dart`
- Modify: `lib/data/repositories/trade_history_repository.dart`
- Read: `lib/domain/services/career_service.dart` (reference)
- Read: `lib/domain/services/trade_history_service.dart` (reference)
- Read: `lib/data/local/hive_service.dart` (reference)

- [ ] **Step 1: 阅读现有 CareerService 中的 Hive 逻辑**

```bash
# 查看 CareerService 如何操作 Hive
grep -n "box\|Hive\|put\|get\|delete" lib/domain/services/career_service.dart
```

- [ ] **Step 2: 实现 HiveCareerRepo**

```dart
// 替换 career_repository.dart 中 HiveCareerRepo 的实现
import 'package:hive/hive.dart';
import 'package:dark_trade_app/data/local/models/career.dart';

class HiveCareerRepo implements CareerRepository {
  static const _boxName = 'careers';

  Box<Career> get _box => Hive.box<Career>(_boxName);

  @override
  Future<List<Career>> loadCareers() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveCareer(Career career) async {
    await _box.put(career.id, career);
  }

  @override
  Future<void> deleteCareer(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> saveAllCareers(List<Career> careers) async {
    final map = {for (final c in careers) c.id: c};
    await _box.putAll(map);
  }

  @override
  Future<List<Career>> migrateFromLocal() async {
    return loadCareers();
  }
}
```

- [ ] **Step 3: 实现 HiveTradeHistoryRepo**

```dart
// 替换 trade_history_repository.dart 中 HiveTradeHistoryRepo 的实现
import 'package:hive/hive.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';

class HiveTradeHistoryRepo implements TradeHistoryRepository {
  static const _boxName = 'tradeHistory';

  Box<TradeRecord> get _box => Hive.box<TradeRecord>(_boxName);

  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async {
    return _box.values.where((r) => r.careerId == careerId).toList();
  }

  @override
  Future<void> saveRecord(TradeRecord record) async {
    await _box.put(record.id, record);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {
    final map = {for (final r in records) r.id: r};
    await _box.putAll(map);
  }

  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async {
    return loadRecords(careerId);
  }
}
```

- [ ] **Step 4: 确保 HiveService 注册了这些 Box**

Read `lib/data/local/hive_service.dart`，确认 `careers` 和 `tradeHistory` box 已注册。如果没有，添加。

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/
git commit -m "feat: implement HiveCareerRepo and HiveTradeHistoryRepo with Hive storage"
```

---

### Task 10: 初始化 Supabase 客户端

**Files:**
- Create: `lib/data/remote/supabase_client.dart`
- Modify: `lib/main.dart` (在 main 中加入 Supabase init)

- [ ] **Step 1: 创建 supabase_client.dart**

```dart
// lib/data/remote/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  SupabaseClientManager._();

  static const _url = 'YOUR_SUPABASE_URL'; // 部署时替换为实际值
  static const _anonKey = 'YOUR_SUPABASE_ANON_KEY'; // 部署时替换

  static late final SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
    client = Supabase.instance.client;
  }

  static SupabaseClient get instance => client;
}
```

- [ ] **Step 2: 在 main.dart 中初始化 Supabase**

Read `lib/main.dart`，在 `HiveService.init()` 之后添加：
```dart
await SupabaseClientManager.init();
```

- [ ] **Step 3: 验证编译**

```bash
cd D:/DarkTradeApp && flutter analyze 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add lib/data/remote/supabase_client.dart lib/main.dart
git commit -m "feat: add Supabase client initialization"
```

---

### Task 11: 创建 SupabaseRemoteRepo

**Files:**
- Create: `lib/data/repositories/supabase_career_repo.dart`
- Create: `lib/data/repositories/supabase_trade_history_repo.dart`
- Modify: 更新 `lib/data/repositories/career_repository.dart` 和 `lib/data/repositories/trade_history_repository.dart` — 确认接口一致

- [ ] **Step 1: 创建 SupabaseCareerRepo**

```dart
// lib/data/repositories/supabase_career_repo.dart
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';

class SupabaseCareerRepo implements CareerRepository {
  @override
  Future<List<Career>> loadCareers() async {
    final userId = SupabaseClientManager.instance.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await SupabaseClientManager.instance
        .from('careers')
        .select()
        .eq('user_id', userId)
        .eq('archived', false);
    return (data as List).map((json) => Career.fromSupabase(json)).toList();
  }

  @override
  Future<void> saveCareer(Career career) async {
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
    await SupabaseClientManager.instance.from('careers').upsert({
      'id': career.id,
      'user_id': userId,
      'name': career.name,
      'initial_balance': career.initialBalance,
      'created_at': career.createdAt.toIso8601String(),
      'archived': false,
    });
  }

  @override
  Future<void> deleteCareer(String id) async {
    await SupabaseClientManager.instance.from('careers').update({'archived': true}).eq('id', id);
  }

  @override
  Future<void> saveAllCareers(List<Career> careers) async {
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
    final rows = careers.map((c) => {
      'id': c.id,
      'user_id': userId,
      'name': c.name,
      'initial_balance': c.initialBalance,
      'created_at': c.createdAt.toIso8601String(),
    }).toList();
    await SupabaseClientManager.instance.from('careers').upsert(rows);
  }

  @override
  Future<List<Career>> migrateFromLocal() async {
    // Implemented in CareerService which reads from local then writes to remote
    return [];
  }
}
```

- [ ] **Step 2: 创建 SupabaseTradeHistoryRepo**

```dart
// lib/data/repositories/supabase_trade_history_repo.dart
import 'package:dark_trade_app/data/local/models/trade_record.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';

class SupabaseTradeHistoryRepo implements TradeHistoryRepository {
  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async {
    final data = await SupabaseClientManager.instance
        .from('trade_records')
        .select()
        .eq('career_id', careerId)
        .order('created_at', ascending: false);
    return (data as List).map((json) => TradeRecord.fromSupabase(json)).toList();
  }

  @override
  Future<void> saveRecord(TradeRecord record) async {
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
    await SupabaseClientManager.instance.from('trade_records').insert({
      'id': record.id,
      'career_id': record.careerId,
      'user_id': userId,
      'direction': record.direction.name,
      'stock_id': record.stockId,
      'symbol': record.symbol,
      'name': record.name,
      'quantity': record.quantity,
      'price': record.price,
      'pnl': record.pnl,
      'created_at': record.createdAt.toIso8601String(),
    });
  }

  @override
  Future<void> deleteRecord(String id) async {
    await SupabaseClientManager.instance.from('trade_records').delete().eq('id', id);
  }

  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {
    final userId = SupabaseClientManager.instance.auth.currentUser!.id;
    final rows = records.map((r) => {
      'id': r.id,
      'career_id': r.careerId,
      'user_id': userId,
      'direction': r.direction.name,
      'stock_id': r.stockId,
      'symbol': r.symbol,
      'name': r.name,
      'quantity': r.quantity,
      'price': r.price,
      'pnl': r.pnl,
      'created_at': r.createdAt.toIso8601String(),
    }).toList();
    await SupabaseClientManager.instance.from('trade_records').insert(rows);
  }

  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async {
    return loadRecords(careerId);
  }
}
```

- [ ] **Step 3: 确保 Career 和 TradeRecord 有 fromSupabase 工厂方法**

Read `lib/data/local/models/career.dart` 和 `lib/data/local/models/trade_record.dart`。检查是否需要添加 `fromSupabase` 工厂构造函数。如果需要，添加。

- [ ] **Step 4: Commit**

```bash
git add lib/data/repositories/
git commit -m "feat: add SupabaseCareerRepo and SupabaseTradeHistoryRepo"
```

---

### Task 12: 改造 CareerService 依赖 Repository

**Files:**
- Modify: `lib/domain/services/career_service.dart`
- Modify: `lib/main.dart` (inject repos)

- [ ] **Step 1: 重写 CareerService**

Read 当前 `lib/domain/services/career_service.dart`。将其改造为接受 Repository：

```dart
// lib/domain/services/career_service.dart (核心改动)
import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';

class CareerService extends ChangeNotifier {
  final CareerRepository _localRepo;
  CareerRepository? _remoteRepo;
  
  List<Career> _careers = [];
  Career? _activeCareer;
  bool _isLoggedIn = false;

  CareerService({required CareerRepository localRepo})
      : _localRepo = localRepo;

  List<Career> get careers => List.unmodifiable(_careers);
  Career? get activeCareer => _activeCareer;

  // 初始化时加载本地生涯
  Future<void> load() async {
    _careers = await _localRepo.loadCareers();
    if (_careers.isNotEmpty) {
      _activeCareer = _careers.first;
    }
    notifyListeners();
  }

  // 登录后设置远程 repo
  void setRemoteRepo(CareerRepository repo) {
    _remoteRepo = repo;
    _isLoggedIn = true;
  }

  // 登出时清除远程
  void clearRemoteRepo() {
    _remoteRepo = null;
    _isLoggedIn = false;
  }

  Future<void> createCareer(String name, double initialBalance) async {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
    );
    _careers.add(career);
    await _localRepo.saveCareer(career);
    if (_remoteRepo != null) {
      await _remoteRepo!.saveCareer(career);
    }
    if (_activeCareer == null) _activeCareer = career;
    notifyListeners();
  }

  void switchCareer(Career career) {
    _activeCareer = career;
    notifyListeners();
  }

  Future<void> deleteCareer(String id) async {
    _careers.removeWhere((c) => c.id == id);
    await _localRepo.deleteCareer(id);
    if (_remoteRepo != null) {
      await _remoteRepo!.deleteCareer(id);
    }
    if (_activeCareer?.id == id) {
      _activeCareer = _careers.isNotEmpty ? _careers.first : null;
    }
    notifyListeners();
  }

  // 游客数据迁移到登录账户
  Future<void> migrateLocalToRemote() async {
    if (_remoteRepo == null) return;
    final localCareers = await _localRepo.migrateFromLocal();
    for (final career in localCareers) {
      await _remoteRepo!.saveCareer(career);
    }
  }
}
```

注意：需要保留 Career 现有的所有字段和方法，此处仅展示新增的 Repository 依赖部分。实际执行时完整合并。

- [ ] **Step 2: 更新 main.dart 注入 local repo**

```dart
// 在 main.dart 中
final careerRepo = HiveCareerRepo();
final careerService = CareerService(localRepo: careerRepo)..load();
```

- [ ] **Step 3: 同样改造 TradeHistoryService**

```dart
// lib/domain/services/trade_history_service.dart 核心改动
class TradeHistoryService extends ChangeNotifier {
  final TradeHistoryRepository _localRepo;
  TradeHistoryRepository? _remoteRepo;
  
  // ... 类似模式
}
```

- [ ] **Step 4: 验证编译**

```bash
cd D:/DarkTradeApp && flutter analyze 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: inject Repository dependencies into CareerService and TradeHistoryService"
```

---

### Task 13: 创建 AuthService

**Files:**
- Create: `lib/domain/services/auth_service.dart`
- Modify: `lib/main.dart` (注入 AuthService)

- [ ] **Step 1: 创建 AuthService**

```dart
// lib/domain/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';

enum AuthState { guest, loggedIn }

class AuthService extends ChangeNotifier {
  AuthState _state = AuthState.guest;
  String? _username;
  String? _userId;

  AuthState get state => _state;
  String? get username => _username;
  String? get userId => _userId;
  bool get isLoggedIn => _state == AuthState.loggedIn;

  AuthService() {
    // 检测是否已有 session
    final session = SupabaseClientManager.instance.auth.currentSession;
    if (session != null) {
      _state = AuthState.loggedIn;
      _userId = session.user.id;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;
    final data = await SupabaseClientManager.instance
        .from('profiles')
        .select('username')
        .eq('id', _userId)
        .maybeSingle();
    if (data != null) {
      _username = (data as Map)['username'] as String?;
    }
    notifyListeners();
  }

  Future<String?> register(String username, String password) async {
    try {
      final email = '$username@darktrade.internal';
      final res = await SupabaseClientManager.instance.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user != null) {
        // 创建 profile
        await SupabaseClientManager.instance.from('profiles').insert({
          'id': res.user!.id,
          'username': username,
          'display_name': username,
        });
        _state = AuthState.loggedIn;
        _userId = res.user!.id;
        _username = username;
        notifyListeners();
        return null; // 成功
      }
      return '注册失败，请重试';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '网络错误，请检查连接';
    }
  }

  Future<String?> login(String username, String password) async {
    try {
      final email = '$username@darktrade.internal';
      await SupabaseClientManager.instance.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _state = AuthState.loggedIn;
      _userId = SupabaseClientManager.instance.auth.currentUser!.id;
      _username = username;
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '网络错误，请检查连接';
    }
  }

  Future<void> logout() async {
    await SupabaseClientManager.instance.auth.signOut();
    _state = AuthState.guest;
    _username = null;
    _userId = null;
    notifyListeners();
  }
}
```

- [ ] **Step 2: 在 main.dart 中注入 AuthService**

在 `MultiProvider` 的 providers 中添加：
```dart
ChangeNotifierProvider(create: (_) => AuthService()),
```

- [ ] **Step 3: Commit**

```bash
git add lib/domain/services/auth_service.dart lib/main.dart
git commit -m "feat: add AuthService with register, login, logout"
```

---

### Task 14: 注册/登录 UI — 个人中心改造

**Files:**
- Modify: `lib/presentation/pages/profile/profile_page.dart`
- Modify: `lib/presentation/widgets/guest_banner.dart`

- [ ] **Step 1: 重写 GuestBanner**

```dart
// lib/presentation/widgets/guest_banner.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.isLoggedIn) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.gold.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(AppText.guestBanner, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(
            onPressed: () => _showAuthSheet(context),
            child: const Text(AppText.registerLogin),
          ),
        ],
      ),
    );
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (_) => const AuthSheet(),
    );
  }
}
```

- [ ] **Step 2: 创建 AuthSheet（注册/登录 底部弹窗）**

```dart
// lib/presentation/pages/profile/auth_sheet.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true; // toggle between login and register
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isLogin ? '登录' : '注册', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: '2-20 位字母、数字或汉字',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.length < 2) return '用户名至少 2 位';
                if (v.length > 20) return '用户名最多 20 位';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                hintText: '6 位以上',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return '密码至少 6 位';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.down, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
              ),
              onPressed: _submit,
              child: Text(_isLogin ? '登录' : '注册'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
              child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    String? error;
    if (_isLogin) {
      error = await auth.login(username, password);
    } else {
      error = await auth.register(username, password);
    }

    if (error != null) {
      setState(() => _error = error);
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }
}
```

- [ ] **Step 3: 更新 ProfilePage 以反映登录状态**

Read 当前 `lib/presentation/pages/profile/profile_page.dart`。检测 `AuthService.isLoggedIn`：
- 未登录：显示"注册 / 登录"按钮 + 头像占位 + "游客模式"标签
- 已登录：显示用户名 + UID + 退出登录按钮

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/guest_banner.dart lib/presentation/pages/profile/
git commit -m "feat: add auth sheet (login/register) and update profile for auth states"
```

---

### Task 15: 游客 → 登录数据迁移

**Files:**
- Create: `lib/presentation/pages/profile/migration_dialog.dart`
- Modify: `lib/domain/services/auth_service.dart` (login 后触发迁移检查)

- [ ] **Step 1: 创建 MigrationDialog**

```dart
// lib/presentation/pages/profile/migration_dialog.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class MigrationDialog extends StatelessWidget {
  final int careerCount;
  final VoidCallback onImport;
  final VoidCallback onSkip;

  const MigrationDialog({
    super.key,
    required this.careerCount,
    required this.onImport,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      title: const Text('导入本地数据'),
      content: Text('检测到本地有 $careerCount 个交易生涯，是否导入到你的账户？'),
      actions: [
        TextButton(onPressed: onSkip, child: const Text('不导入')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
          onPressed: onImport,
          child: const Text('导入'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 在 AuthSheet 的 login/register 成功后触发迁移检查**

在 `AuthSheet._submit()` 中，成功后先检查是否需要迁移：

```dart
// 在 AuthSheet._submit 中
if (error != null) { ... } else {
  // 检查本地是否有数据需要迁移
  final careerService = context.read<CareerService>();
  if (careerService.careers.isNotEmpty && mounted) {
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (_) => MigrationDialog(
        careerCount: careerService.careers.length,
        onImport: () => Navigator.pop(context, true),
        onSkip: () => Navigator.pop(context, false),
      ),
    );
    if (shouldImport == true) {
      await careerService.migrateLocalToRemote();
    }
  }
  if (mounted) Navigator.of(context).pop();
}
```

- [ ] **Step 3: 在 ProfilePage 中实现退出登录**

退出登录时调用 `authService.logout()`，`CareerService.clearRemoteRepo()`。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add guest-to-login data migration flow and logout support"
```

---

### Task 16: 新手引导

**Files:**
- Create: `lib/presentation/widgets/onboarding_dialog.dart`
- Modify: `lib/app/main_tabs_page.dart` (引导浮层)
- Modify: `lib/main.dart` 或 `lib/domain/services/career_service.dart` (首次检测)

- [ ] **Step 1: 创建 WelcomeDialog**

```dart
// lib/presentation/widgets/onboarding_dialog.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class WelcomeDialog extends StatefulWidget {
  final void Function(String name, double balance) onConfirm;
  const WelcomeDialog({super.key, required this.onConfirm});

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  final _nameCtrl = TextEditingController(text: '我的生涯 #1');
  final _balanceCtrl = TextEditingController(text: '100000');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDims.radiusLg)),
      title: const Text('欢迎来到 DarkTrade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('这里是一个免费练习 A 股交易的虚拟平台。不用担心亏损，大胆尝试你的交易策略！'),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '生涯名称', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '初始资金 (¥)', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 100000;
            if (name.isEmpty) return;
            widget.onConfirm(name, balance.clamp(1, 100000000));
          },
          child: const Text('开始交易'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 在 MainTabsPage 的 initState 中触发引导**

```dart
// lib/app/main_tabs_page.dart — 在 State.initState 中
@override
void initState() {
  super.initState();
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
          _showTabHint(); // 步骤2: 高亮行情Tab
        },
      ),
    );
  }
}

void _showTabHint() {
  // 闪烁行情 Tab + 浮层提示 "从这里探索 A 股市场"
  // 使用 overlay 或 SnackBar 实现
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('👆 从这里探索 A 股市场'),
      backgroundColor: AppColors.gold,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add onboarding flow (welcome dialog + create career + tab hint)"
```

---

### Task 17: 合规层

**Files:**
- Create: `lib/presentation/widgets/risk_disclaimer.dart`
- Modify: `lib/presentation/pages/market/market_page.dart` (延迟标注)
- Modify: `lib/presentation/pages/trade/trade_page.dart` (底部免责)

- [ ] **Step 1: 创建 RiskDisclaimerDialog**

```dart
// lib/presentation/widgets/risk_disclaimer.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class RiskDisclaimerDialog extends StatefulWidget {
  const RiskDisclaimerDialog({super.key});

  @override
  State<RiskDisclaimerDialog> createState() => _RiskDisclaimerDialogState();
}

class _RiskDisclaimerDialogState extends State<RiskDisclaimerDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDims.radiusLg)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(AppText.riskTitle),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppText.riskBody),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  activeColor: AppColors.gold,
                ),
                Expanded(child: Text(AppText.agreeTerms, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _agreed ? AppColors.gold : AppColors.unselectedBg,
          ),
          onPressed: _agreed ? () => Navigator.of(context).pop(true) : null,
          child: const Text('确认并继续'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 在 MainTabsPage 中触发风险提示**

```dart
// 使用 SharedPreferences 或 Hive 记录是否已同意
// 首次启动且未同意时，在 WelcomeDialog 之后显示 RiskDisclaimerDialog
```

- [ ] **Step 3: 在交易页底部添加免责文字**

在 `trade_page.dart` 底部添加：
```dart
Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    AppText.disclaimerFooter,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall,
  ),
),
```

- [ ] **Step 4: 行情页已有数据延迟标注（Task 7 已添加）**

确认 `market_page.dart` 中的 `AppText.dataDelayNote` 显示正常。

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add compliance layer (risk disclaimer, footer text, data delay note)"
```

---

### Task 18: Tips 系统

**Files:**
- Create: `lib/presentation/widgets/tip_bubble.dart`
- Modify: `lib/presentation/pages/trade/trade_page.dart` (集成 Tips)

- [ ] **Step 1: 创建 TipBubble 组件和 Tip 数据**

```dart
// lib/presentation/widgets/tip_bubble.dart
import 'dart:math';
import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class TipData {
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTip());
  }

  void _maybeShowTip() {
    // ~20% 概率显示
    if (Random().nextDouble() < 0.2) {
      _showRandomTip();
    }
  }

  void _showRandomTip() {
    if (_visible) return;
    _currentTip = TipData.all[Random().nextInt(TipData.all.length)];
    _visible = true;
    setState(() {});
    _controller.forward();
    // 5 秒后自动消失
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            setState(() => _visible = false);
          }
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
          color: AppColors.gold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDims.radiusSm),
          border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(child: Text(_currentTip!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            GestureDetector(
              onTap: () => _controller.reverse().then((_) {
                if (mounted) setState(() => _visible = false);
              }),
              child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 在交易页集成 TipBubble**

在 `trade_page.dart` 的 body 底部，ExecuteButton 上方添加：
```dart
const TipBubble(),
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/tip_bubble.dart lib/presentation/pages/trade/trade_page.dart
git commit -m "feat: add random tip bubble system for trade page"
```

---

### Task 19: PWA 配置 & Web 准备

**Files:**
- Modify: `web/manifest.json`
- Modify: `web/index.html`

- [ ] **Step 1: 更新 manifest.json**

读当前 `web/manifest.json`，更新：
```json
{
  "name": "DarkTrade - A股模拟交易",
  "short_name": "DarkTrade",
  "description": "面向新手的A股模拟交易练习平台，零成本体验真实交易流程",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFBF5",
  "theme_color": "#FFFBF5",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

- [ ] **Step 2: 更新 index.html meta 标签**

Read `web/index.html`，更新：
- `<meta name="description">` → "面向新手的A股模拟交易练习平台，零成本体验真实交易流程"
- `<title>` → "DarkTrade - A股模拟交易"
- `<meta name="apple-mobile-web-app-title">` → "DarkTrade"

- [ ] **Step 3: Commit**

```bash
git add web/manifest.json web/index.html
git commit -m "chore: update PWA manifest and meta tags for production"
```

---

### Task 20: 构建 & 验证

**Files:** None (构建输出)

- [ ] **Step 1: 运行 flutter analyze 确保无错误**

```bash
cd D:/DarkTradeApp && flutter analyze 2>&1
```

Expected: No errors. Fix any found before proceeding.

- [ ] **Step 2: 构建 Web release**

```bash
cd D:/DarkTradeApp && flutter build web --release --web-renderer canvaskit 2>&1
```

Expected: Build successful. Output in `build/web/`.

- [ ] **Step 3: 本地测试**

```bash
cd D:/DarkTradeApp && flutter run -d chrome --release
```

手动测试：
- [ ] App 正常启动，显示亮色暖调主题
- [ ] 行情页显示 A 股数据
- [ ] 首次启动触发欢迎弹窗
- [ ] 风险提示弹窗正常
- [ ] 交易页 Tips 随机出现
- [ ] 注册/登录 弹窗可用
- [ ] GuestBanner 显示正确
- [ ] 个人中心未登录/已登录状态切换正确

- [ ] **Step 4: Commit release build 配置**

```bash
git add -A
git commit -m "chore: finalize production build, all systems verified"
```

---

### Task 21: Vercel 部署

- [ ] **Step 1: 安装 Vercel CLI（如未安装）**

```bash
npm install -g vercel
```

- [ ] **Step 2: 部署**

```bash
cd D:/DarkTradeApp && vercel --prod --cwd build/web
```

按照提示完成首次部署配置。

- [ ] **Step 3: 验证线上环境**

浏览器打开 Vercel 分配的 URL，执行 Task 20 的测试清单。

---

## P1 / P2 后续

详见 spec 文档第 14 节优先级表。P1 包括：成就勋章、教程系统、战绩分享图、情绪仪表盘、资产页收尾。P2 包括：排行榜、好友对战、会员系统、微信小程序。

---

**Plan complete.**
