# DarkTrade App — 项目进度与待办

> 最后更新：2026-05-16  
> 技术栈：Flutter · Provider · http · CoinGecko（行情）

---

## 一、项目当前状态（一句话）

**黑金风四 Tab 壳子 + 行情页已接 CoinGecko 真实数据；资产 / 交易 / 个人中心以 UI + 演示数据为主，尚未接后端或链上账户。**

---

## 二、已完成 ✅

### 工程与架构
- [x] 标准 Flutter 工程（`pubspec.yaml`、`lib/`、`analysis_options.yaml`、Web 支持）
- [x] 从 FlutterFlow 导出的 **Market Explorer** 页面与组件（`market_explorer.dart`、chip / stock_row / text_field）
- [x] 精简版 **flutter_flow** 工具层（theme、model、util、icon_button）
- [x] **Provider** 注入全局 `LiveMarketService`
- [x] **MainTabsPage**：`IndexedStack` + 底部四 Tab，切换保留各页状态
- [x] 全局 **黑金主题**（背景 `#0D0D0D`，强调色 `#FFD700`）

### 四个 Tab 页面
| Tab | 文件 | 完成度 |
|-----|------|--------|
| 行情 Explore | `lib/market_explorer.dart` | UI 完整 + **真实行情** |
| 资产 Assets | `lib/assets_page.dart` | UI 完整，**静态演示数据** |
| 交易 Trade | `lib/trade_page.dart` | UI 完整，**本地校验 + SnackBar**，无真实下单 |
| 个人 Profile | `lib/profile_page.dart` | UI 完整，**菜单/退出为演示** |

### 行情服务 `lib/services/live_market_service.dart`
- [x] CoinGecko Markets API（Top 20，`sparkline=true`）
- [x] 字段映射：`id` / `symbol`（大写）/ `name` / `current_price` / `price_change_percentage_24h` / `sparkline_in_7d`
- [x] 每 **60 秒** 自动刷新
- [x] 失败时 **保留上次数据** + `lastNetworkNote` / `lastError` 提示
- [x] 汇总 `total_volume` → 页面「Vol. (24h)」

### 其它
- [x] 行情页 FAB → `TradeExecutionWidget`（占位页，Navigator 打开）
- [x] 交易页「立即执行」：非空校验、黑金 SnackBar、清空输入、HapticFeedback
- [x] 基础冒烟测试 `test/widget_test.dart`
- [x] `flutter analyze` 无 error（仅 info/warning）

---

## 三、未完成 / 仅占位 ⚠️

### 行情（Market Explorer）
- [ ] API 返回 **20 条**，列表 UI 仍绑定 **7 个** `stockRowModel`，最多只显示 7 条 → 需改为 **动态 ListView**
- [ ] 分类 Chip（Trending / Technology / Energy…）**未过滤数据**（文案偏股票，数据已是加密货币）
- [ ] 「SEE ALL」按钮 **无跳转**
- [ ] 点击某币种 **无详情页**（K 线、深度等）
- [ ] 通知按钮仅展示 `lastNetworkNote`，无独立通知中心
- [ ] CoinGecko **免费额度 / 429** 需考虑降级策略（拉长刷新间隔、本地缓存时间戳等）

### 资产（Assets）
- [ ] 总资产、分布、持仓均为 **写死的演示数据**（BTC/USDT/ETH）
- [ ] 未与行情服务或钱包 API 联动
- [ ] 无充值 / 提现 / 划转入口

### 交易（Trade）
- [ ] 无 **交易对选择**（未与行情列表联动）
- [ ] 无真实 **下单 API**（限价/市价、手续费、余额校验）
- [ ] 快捷比例基于写死的 `_demoMaxQty`，非真实可用余额
- [ ] 底部 Tab「交易」与行情 FAB 打开的 **`TradeExecutionWidget` 未统一**（两套入口）

### 个人（Profile）
- [ ] 账号安全 / 费率 / 通知 / 关于 → 仅 SnackBar 演示
- [ ] 退出登录无真实鉴权流程
- [ ] 无登录 / 注册 / KYC

### 工程与质量
- [ ] 无 **持久化**（SharedPreferences / secure_storage）
- [ ] 无 **路由方案**（已移除 go_router，仅 `MaterialApp.home`）
- [ ] 无 **README** 运行说明与环境要求（可选）
- [ ] 单元测试 / 集成测试覆盖不足（仅 1 个 widget smoke test）
- [ ] `pubspec.yaml` 的 description 仍写 “mock live quotes”，可更新文案

---

## 四、目录速查

```
lib/
├── main.dart                 # 入口、主题、Provider
├── app/main_tabs_page.dart   # 四 Tab 壳子
├── market_explorer.dart      # 行情页（FlutterFlow + CoinGecko）
├── assets_page.dart          # 资产页（演示）
├── trade_page.dart           # 交易下单页（演示）
├── profile_page.dart         # 个人中心（演示）
├── services/
│   └── live_market_service.dart  # CoinGecko 行情
├── components/               # chip、stock_row、text_field
├── flutter_flow/             # 主题与工具
└── pages/
    └── trade_execution_widget.dart  # FAB 占位页
```

---

## 五、下次回来建议从哪里开始 🚀

### 推荐优先级（按性价比）

**1. 行情列表补齐（建议第一站）**  
文件：`lib/market_explorer.dart`  
- 用 `ListView.builder` 替代 7 个固定 `stockRowModel`  
- 直接绑定 `market.quotes`（最多 20 条）  
- 顺带处理加载中 / 错误 / 空列表 UI（可读 `market.lastError`、`market.isUsingCachedData`）

**2. 交易与行情打通**  
文件：`lib/trade_page.dart`、`lib/market_explorer.dart`  
- 点击行情行 → 把 `symbol` / `current_price` 带到交易页  
- 决定保留 `TradeExecutionWidget` 还是删掉，**只保留 Tab 内 `TradePage`**

**3. 资产页接数据**  
文件：`lib/assets_page.dart`、新建 `lib/services/portfolio_service.dart`  
- 先用本地 Mock + Provider，结构与 `LiveMarketService` 一致  
- 后续再接交易所 API 或自建后端

**4. 分类与搜索**  
- Chip 改为按 CoinGecko `categories` 或自定义标签过滤  
- 或简化为「全部 / 涨幅榜 / 跌幅榜」等基于已有字段排序

### 本地运行

```powershell
cd d:\DarkTradeApp
flutter pub get
flutter run          # 需网络（CoinGecko）
# 或
flutter run -d chrome
```

### 关键依赖

- 行情：`https://api.coingecko.com/api/v3/coins/markets?...`
- 状态：`LiveMarketService`（`context.watch` / `Provider`）

---

## 六、已知问题 / 备注

| 问题 | 说明 |
|------|------|
| 行情仅显示 7 条 | `MarketExplorerModel` 只创建了 7 个 `StockRowModel` |
| 分类标签与数据不符 | UI 为股票板块名，数据为加密货币 |
| 交易 FAB 重复 | 行情 FAB → 旧占位页；底部 Tab → 新 `TradePage` |
| 离线 / 限流 | 服务会保留旧数据；注意 CoinGecko 429，可适当改为 90–120s 刷新 |

---

## 七、里程碑勾选（自用）

- [x] M0：Flutter 工程可运行  
- [x] M1：四 Tab 黑金 UI  
- [x] M2：CoinGecko 真实行情  
- [ ] M3：行情列表完整 + 币种详情  
- [ ] M4：交易闭环（选币 → 下单 → 反馈）  
- [ ] M5：资产与持仓真实数据  
- [ ] M6：账号体系与持久化  

---

*回到项目时：先看 **第五节优先级 1**，改 `market_explorer.dart` 动态列表，收益最大。*
