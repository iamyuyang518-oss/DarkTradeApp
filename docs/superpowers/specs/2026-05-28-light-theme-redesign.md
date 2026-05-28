# Light Warm Theme Redesign + Remove US Stocks

> 日期：2026-05-28
> 基于用户反馈，将 UI 从暗黑专业风格转向亮色暖调新手友好风格

---

## 一、改动摘要

1. **移除美股展示** — 行情页 Tab 从 3 个减为 2 个（加密货币 + A股）
2. **亮色暖调主题** — 全局色彩从深色黑金 → 暖白琥珀

---

## 二、色彩系统

```
背景底色:    #FFFBF5 (暖白)
卡片底色:    #FFFFFF (纯白)
卡片边框:    #E8DCC8 (浅米色)
强调色:      #D4A853 (琥珀金)
主文字:      #3D3025 (深褐)
辅助文字:    #A09078 (暖灰)
涨色:        #43A047 / #E8F5E9 (绿 + 浅绿底)
跌色:        #E57373 / #FFF0F0 (红 + 浅红底)
选中态:      #D4A853 实心金 + 白色字
未选中态:    #F5EDE0 米色底 + #B8976A 字
```

---

## 三、行情页改造

### 3.1 去美股
- TabBar tabs: `['加密货币', 'A股']` (原 `['加密货币', '美股', 'A股']`)
- TabController length: 2
- _serviceForTab: index 0 → LiveMarketService, index 1 → AShareService
- 移除 isUsStock 相关的 category

### 3.2 新增情绪仪表盘
- 顶部卡片：市场情绪指数 (0-100) + 三级色条 (恐慌→观望→贪婪)
- 计算方式：上涨股票数 / 总数 * 50 + 50 (中性偏上)
- 显示涨跌家数统计

### 3.3 股票卡片升级
- 代号 + 名称分两行显示
- 板块标签带颜色底
- 内嵌迷你走势条 (8段 sparkline)
- 涨跌用有色底标签 (浅绿底/浅红底)
- 显示当日最高/最低价

### 3.4 新手提示条
- 底部虚线边框提示卡片
- 内容："点击任意股票卡片，查看详细 K 线走势和交易入口"

---

## 四、主题文件改造

改动 `flutter_flow/flutter_flow_theme.dart`:
- primaryBackground: #0D0D0D → #FFFBF5
- secondaryBackground: #1A1A1A → #FFFFFF
- primaryText: #FFFFFF → #3D3025
- secondaryText: #B0B0B0 → #A09078
- alternate (边框/分割线): #2A2A2A → #E8DCC8
- primary (强调色): #FFD700 → #D4A853
- success: #16A34A → #43A047
- scaffoldBackgroundColor: #0D0D0D → #FFFBF5

所有页面（资产、交易、个人、详情）自动跟随主题变量。

---

## 五、不在此范围

- 其他功能页面布局不变
- 不碰后端/数据层
- 不修改 K 线图渲染逻辑
- 新手引导系统（后续迭代）
