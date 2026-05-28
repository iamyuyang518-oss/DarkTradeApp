# DarkTrade App — 项目进度与待办

> 最后更新：2026-05-28
> 技术栈：Flutter · Provider · Hive · Supabase · 东方财富 API

---

## 一、项目当前状态

**A 股模拟交易平台，亮色暖调主题 + 四 Tab 壳子，已接入东方财富真实行情，生涯系统 + 交易闭环 + 本地持久化已完成。正在向 MVP 公测版本推进。**

---

## 二、已完成 ✅

### 工程与架构
- [x] 标准 Flutter 工程（Web 支持）
- [x] Provider 注入全局服务
- [x] MainTabsPage：IndexedStack + 底部四 Tab
- [x] Hive 本地持久化（生涯 + 交易记录 + 持仓）
- [x] 数据模型：Career、TradeRecord（含 Hive 适配器）

### 行情
- [x] 东方财富 A 股行情 API（通过 CORS 代理）
- [x] AShareService 定时刷新
- [x] 动态 ListView.builder 替代硬编码列表
- [x] StockDetailPage：K 线图表 + 交易入口
- [x] AShareService 失败保留上次数据

### 资产
- [x] GainLossCard 收益概览卡片
- [x] EquityCurveChart 净值迷你曲线
- [x] CareerSelector 生涯选择器 + CareerManagementSheet
- [x] PortfolioService 持仓计算 + 模拟数据

### 交易
- [x] TradePage 完整下单（买入/卖出 + 价格/数量 + 快捷比例）
- [x] SymbolPickerSheet — 从行情列表选择交易对
- [x] 可用余额显示 + 撒花成功动效
- [x] 限价/市价 + 余额校验 + 交易闭环
- [x] CareerService + TradeHistoryService 打通交易执行

### 个人中心
- [x] 游客/登录双状态 UI
- [x] TradeHistoryPage 交易记录（筛选 + 空状态）
- [x] GuestBanner 游客提示条

### 主题
- [x] 亮色暖调主题（#FFFBF5 暖白底 + #D4A853 琥珀金）
- [x] 全局色彩系统统一

---

## 三、MVP 待办（P0 — 公测前必须完成）

### 目录重组
- [ ] 按新目录结构重组 lib/（参考设计文档第二节）
- [ ] 删除 `flutter_flow/`，主题并入 `core/theme.dart`
- [ ] 删除重复 `lib/trade_page.dart` 和 `pages/trade_execution_widget.dart`
- [ ] 移除 `LiveMarketService`、`UsStockService`（加密货币/美股代码）
- [ ] 移除行情页多 Tab，仅保留 A 股

### Repository 层
- [ ] 创建 `CareerRepository` 和 `TradeHistoryRepository` 接口
- [ ] 实现 `HiveLocalRepo`（已有 HiveService，改接口）
- [ ] 初始化 Supabase 客户端
- [ ] 实现 `SupabaseRemoteRepo`
- [ ] CareerService 改造为依赖 Repository

### 账号系统
- [ ] `AuthService`：注册（用户名+密码 → Supabase Auth）
- [ ] `AuthService`：登录 / 登出
- [ ] 游客模式保持（数据走 HiveLocalRepo）
- [ ] 游客 → 登录数据迁移流程
- [ ] 个人中心登录态（用户名 + UID 显示）
- [ ] 退出登录 → 回退游客模式

### 新手引导
- [ ] 欢迎弹窗（首次启动检测本地无数据）
- [ ] 创建首个生涯（名称 + 初始资金）
- [ ] 底部 Tab 行情高亮闪烁 + 浮层提示

### 合规层
- [ ] 风险提示弹窗（首次 + 每日首次交易前）
- [ ] 交易页底部常驻免责文字
- [ ] 行情页数据延迟标注（"可能存在五分钟延迟"）

### Tips 系统
- [ ] TipBubble 组件（随机出现 + 自动消失）
- [ ] 12 条预置 Tips 配置
- [ ] 已读去重逻辑

### PWA & 部署
- [ ] 更新 `web/manifest.json`（name, description, theme_color: #FFFBF5）
- [ ] 更新 `web/index.html` meta description
- [ ] 替换 `web/favicon.png` 为项目 Logo
- [ ] PWA Service Worker 离线支持
- [ ] `flutter build web --release` 验证
- [ ] Vercel 部署 + 冒烟测试

---

## 四、P1 — 上线后迭代

- [ ] 成就勋章系统（15 枚，MVP 先做 8-10 枚）
- [ ] 教程系统（7 章，可配置）
- [ ] 战绩分享图导出（RepaintBoundary + share_plus）
- [ ] 情绪仪表盘（佛系/吃瓜/上头）
- [ ] 资产页收尾

## 五、P2 — 社交 + 商业化

- [ ] Supabase 远程排行榜（周/月/总）
- [ ] 好友对战系统（房间 + 邀请码）
- [ ] 会员系统 + 加密货币市场解锁
- [ ] 微信小程序（独立技术栈）
- [ ] 独立域名购买绑定

---

## 六、目录速查（重组后目标结构）

```
lib/
├── main.dart
├── app/                    # 入口、路由、主题
├── core/                   # 常量、主题、扩展
├── data/
│   ├── local/              # Hive 模型 + 服务
│   ├── remote/             # Supabase + 东方财富 API
│   └── repositories/       # 仓库接口与实现
├── domain/
│   ├── services/           # 业务逻辑
│   └── models/             # 领域模型
└── presentation/
    ├── pages/              # 行情/资产/交易/个人/教程
    │   ├── market/
    │   ├── assets/
    │   ├── trade/
    │   ├── profile/
    │   └── tutorial/
    └── widgets/            # 共享组件
```

---

## 七、里程碑

- [x] M0：Flutter 工程可运行
- [x] M1：四 Tab 黑金 UI
- [x] M2：CoinGecko 真实行情
- [x] M3：切换到 A 股 + 亮色暖调主题
- [x] M4：生涯系统 + 交易闭环 + 本地持久化
- [ ] M5：账号系统 + 游客模式 + 数据迁移（← 当前）
- [ ] M6：合规层 + 新手引导 + Tips + PWA 部署 → **MVP 公测**
- [ ] M7：成就 + 教程 + 分享图 + 情绪仪表盘
- [ ] M8：排行榜 + 好友对战 + 会员系统

---

## 八、本地运行

```powershell
cd D:\DarkTradeApp
flutter pub get
flutter run -d chrome
```

## 九、关键依赖

- 行情：东方财富 API（通过 CORS 代理）
- 状态管理：Provider
- 本地存储：Hive
- 远程存储/Auth：Supabase
- 分享：share_plus

## 十、设计文档

- [MVP 发布设计文档](docs/superpowers/specs/2026-05-28-mvp-launch-design.md)
- [V2 设计文档（旧）](docs/superpowers/specs/2026-05-28-darktrade-v2-design.md)
- [亮色主题改造](docs/superpowers/specs/2026-05-28-light-theme-redesign.md)
