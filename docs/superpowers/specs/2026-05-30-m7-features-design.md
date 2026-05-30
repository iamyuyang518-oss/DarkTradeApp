# DarkTrade M7 功能设计文档

> 日期：2026-05-30
> 目标：行情页三Tab改造 + 资产页收尾 + 成就系统 + 教程系统 + 情绪仪表盘 + 分享图
> 定位：M7 里程碑，完善新手体验和留存激励

---

## 一、行情页三 Tab 改造（最高优先级）

### 1.1 设计目标

将当前单一"全部A股"列表改为三Tab结构，登录后个性化展示。

### 1.2 Tab 结构

| Tab | 名称 | 数据来源 | 登录默认 | 游客默认 |
|-----|------|---------|---------|---------|
| ⭐ | 关注 | WatchlistRepository（新增） | 有关注时默认 | Hive本地 |
| 📦 | 持仓 | PortfolioService（已有） | 有持仓时显示 | 空状态引导登录 |
| 🔥 | 热门 | AShareService Top20 排序 | 无关注时默认 | **默认Tab** |

### 1.3 新增：WatchlistRepository

```
lib/data/repositories/watchlist_repository.dart        # 接口
lib/data/local/hive_watchlist_repo.dart                 # Hive 实现
lib/data/remote/supabase_watchlist_repo.dart            # Supabase 实现
lib/domain/services/watchlist_service.dart              # 业务逻辑 + ChangeNotifier
```

**接口方法：**
```dart
abstract class WatchlistRepository {
  Future<List<String>> getWatchedSymbols();       // 返回股票代码列表
  Future<void> addSymbol(String symbol);
  Future<void> removeSymbol(String symbol);
  Future<bool> isWatched(String symbol);
  Future<void> clear();                           // 退出登录时清理
}
```

**Hive 存储：**
- Box: `watchlist`，key: 用户ID（游客用 `guest`）
- Value: `List<String>` 股票代码列表

**Supabase 存储：**
- 表: `watchlists`，字段: `user_id`, `symbol`, `created_at`
- 主键: `(user_id, symbol)`

### 1.4 行情页 UI 改动

**顶部 Tab 栏：** 替换现有行业分类 chips，改为三Tab切换
```dart
enum MarketTab { watchlist, holdings, hot }

// TabBar in SliverAppBar or Column header
TabBar(
  tabs: [
    Tab(text: '⭐ 关注'),
    Tab(text: '📦 持仓'),  
    Tab(text: '🔥 热门'),
  ],
)
```

**每行新增星标按钮：**
- 热门Tab：右侧 `☆` 空心星 → 点击加关注
- 关注Tab：右侧 `★` 实心星（金色）→ 点击取消关注
- 持仓Tab：显示持有数量和盈亏，也可加星标

**空状态处理：**
- 关注Tab为空 → "还没有关注股票，去🔥热门发现吧"
- 持仓Tab为空 → "还没有持仓，去交易页开始吧"
- 热门Tab为空 → 加载中/网络错误重试

### 1.5 现有代码改动

- `market_page.dart`：重构为三Tab结构，拆分 `_buildStockList` 为三个方法
- 新增 `WatchlistService` 注入 Provider
- `main.dart` / `app.dart`：注册新 Service

---

## 二、资产页收尾

### 2.1 当前问题

1. 计价单位写死为 USDT（`_formatUsd`），需改为人民币 ¥
2. `GainLossCard` `todayPnl` 硬编码为 0
3. 颜色用黑色主题（`Color(0xFF121212)`），与暖调主题不一致
4. 资产分布只有文字+进度条，缺少饼图

### 2.2 改动清单

| 项目 | 当前 | 改为 |
|------|------|------|
| 计价单位 | `$` USDT | `¥` RMB |
| 今日盈亏 | `todayPnl: 0` | 根据持仓×当日涨跌幅实时计算 |
| 卡片背景 | `#121212` 黑色 | `#FFFFFF` 白色 + 暖调边框 |
| 文字颜色 | `#3D3025` 视为"白" | 正确使用 `_textPrimary` |
| 资产分布 | 纯文字列表 | 顶部增加简易饼图环（占位 SVG/CustomPaint） |

### 2.3 今日盈亏计算

```dart
double computeTodayPnl(List<Holding> holdings, Map<String, StockQuote> quotes) {
  double pnl = 0;
  for (final h in holdings) {
    final quote = quotes[h.symbol];
    if (quote != null) {
      pnl += h.amount * (quote.change ?? 0); // change = 当日涨跌额
    }
  }
  return pnl;
}
```

---

## 三、成就勋章系统

### 3.1 设计

15 枚勋章，MVP 实现 8-10 枚。出现在个人中心页。

### 3.2 勋章列表（优先实现）

| 勋章 | 解锁条件 | 图标 | 难度 |
|------|---------|------|------|
| 🍼 新手交易员 | 完成第一笔交易 | 奶瓶 | 入门 |
| 🎯 首次盈利 | 单笔交易盈利 > 0 | 靶心 | 入门 |
| 📈 连赢三把 | 连续3笔交易盈利 | 上升箭头 | 入门 |
| 💰 万元户 | 总资产突破 10,000 ¥ | 钱袋 | 进阶 |
| 🔥 交易狂热 | 单日交易 ≥ 10 笔 | 火焰 | 进阶 |
| 💎 钻石手 | 持仓 > 7 天不卖出 | 钻石 | 进阶 |
| 🦈 抄底王 | 当日最低价买入 | 鲨鱼 | 进阶 |
| 🚀 逃顶高手 | 当日最高价卖出 | 火箭 | 进阶 |
| 🎓 学业有成 | 完成全部7章教程 | 学士帽 | 特殊 |
| 📊 股神降临 | 总收益率 ≥ 50% | 皇冠 | 传说 |

### 3.3 数据模型

```dart
class Achievement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;
}

// AchievementService extends ChangeNotifier
// 在交易结算后检查解锁条件，持久化到 Hive `achievements` box
```

### 3.4 UI

- 个人中心页新增"成就墙"区域
- 未解锁：灰色 + 🔒
- 已解锁：彩色 emoji + 名称 + 解锁日期
- 新解锁时弹出 Toast/小窗祝贺

---

## 四、教程系统

### 4.1 7 章结构

| 章 | 标题 | 内容要点 |
|----|------|---------|
| 1 | 欢迎来到A股 | A股是什么、交易时间、T+1规则 |
| 2 | 看懂K线图 | 阴阳烛、均线、成交量 |
| 3 | 限价单 vs 市价单 | 两种订单类型的区别和适用场景 |
| 4 | 建立你的第一个持仓 | 如何选股、下单买入 |
| 5 | 何时卖出 | 止盈止损、持仓管理 |
| 6 | 读懂市场情绪 | 涨跌比、成交量、热门板块 |
| 7 | 进阶技巧 | 风险控制、组合管理、避免常见错误 |

### 4.2 实现方式

- `TutorialPage`：全屏教程页面，Step-by-Step 翻页
- 每页：标题 + 插图(emoji/图标) + 说明文字 + "上一页/下一页"
- 从个人中心进入，也可在首次注册后弹出引导
- 进度持久化到 Hive `tutorial_progress` box
- 可跳过、随时返回

### 4.3 数据配置

```dart
// lib/domain/models/tutorial_chapter.dart
class TutorialChapter {
  final int index;
  final String title;
  final String emoji;
  final String content; // Markdown or rich text
}
// 7章硬编码在常量配置中，方便后续改为远程配置
```

---

## 五、情绪仪表盘

### 5.1 设计

利用现有行情页已有的"市场情绪"卡片逻辑，扩展为三种用户情绪标签。

### 5.2 情绪判断规则

| 情绪 | 条件 | 图标 | 文案 |
|------|------|------|------|
| 🧘 佛系 | 近7天交易 ≤ 1 笔 | 🧘 | 淡定持有，心如止水 |
| 🍿 吃瓜 | 近7天交易 2-5 笔 | 🍿 | 观望中，吃瓜看戏 |
| 🔥 上头 | 近7天交易 ≥ 6 笔 | 🔥 | 交易频繁，注意休息 |

### 5.3 UI

- 在资产页顶部显示当前情绪标签
- 如果已有"市场情绪"卡片则合并展示
- 轻量实现：一个带 emoji 的 Chip/Badge

---

## 六、战绩分享图导出

### 6.1 设计

用户可以将收益表现导出为精美图片，分享到微信/朋友圈。

### 6.2 分享图内容

- DarkTrade Logo + 标题
- 收益曲线（EquityCurveChart 截图）
- 关键数据：总收益率、总资产、交易笔数、胜率
- 底部二维码 → 引导下载/打开 DarkTrade
- 暖调主题边框装饰

### 6.3 技术实现

```dart
// 使用 RepaintBoundary + RenderRepaintBoundary.toImage()
// + share_plus 分享图片

class ShareCard extends StatelessWidget {
  // Build a fixed-size card widget
  // Wrapped in RepaintBoundary with a GlobalKey
}

// ShareService:
// 1. Render ShareCard to image via RepaintBoundary
// 2. Convert to png bytes
// 3. Share via share_plus
```

---

## 七、实施顺序

按用户价值和技术依赖排序：

| 阶段 | 功能 | 预计文件数 | 依赖 |
|------|------|-----------|------|
| 1 | 行情页三Tab + Watchlist | ~5 新文件 + 1 重构 | 无 |
| 2 | 资产页收尾 | 1 修改 | 无 |
| 3 | 成就勋章系统 | ~3 新文件 | 交易数据（已有） |
| 4 | 教程系统 | ~2 新文件 | 无 |
| 5 | 情绪仪表盘 | 1 修改（资产页） | 交易记录（已有） |
| 6 | 战绩分享图 | ~2 新文件 | 收益曲线（已有） |

---

## 八、新增/修改文件总览

### 新增文件
```
lib/domain/services/watchlist_service.dart
lib/data/repositories/watchlist_repository.dart
lib/data/local/hive_watchlist_repo.dart
lib/data/remote/supabase_watchlist_repo.dart
lib/domain/services/achievement_service.dart
lib/domain/models/achievement.dart
lib/data/local/hive_achievement_repo.dart
lib/domain/models/tutorial_chapter.dart
lib/presentation/pages/tutorial/tutorial_page.dart
lib/domain/services/share_service.dart
lib/presentation/widgets/share_card.dart
```

### 修改文件
```
lib/presentation/pages/market/market_page.dart         # 重构为三Tab
lib/presentation/pages/assets/assets_page.dart         # 暖调主题 + RMB + 今日盈亏
lib/presentation/pages/profile/profile_page.dart       # 新增成就墙入口
lib/app/app.dart 或 main.dart                          # 注册新 Service
```

---

## 九、不涉及的范围

- PWA Service Worker 离线支持（已跳过）
- Supabase 排行榜（M8）
- 好友对战系统（M8）
- 会员系统（M8）
- 微信小程序（独立项目）
