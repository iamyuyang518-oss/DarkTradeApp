# Changelog

All notable changes to DarkTrade will be documented in this file.

---

## M8 — UI Warm Redesign (2026-06-03)

### 🎨 Design Tokens (Phase 1)
- **New warm color palette:** Background `#FFF9F0`, Gold accent `#D4A853`, warm brown text `#4A3828`, softer up/down colors
- **Unified border radii:** `radiusXs`–`radiusXl` scale (4–18px) across all components
- **Spacing system:** `gapXs`–`gapLg` + `paddingPage`/`paddingCard` constants
- **Shadow presets:** `AppShadows.card`, `.hover`, `.modal`, `.goldButton` — warm-tinted shadows
- **Emotion color palette:** Zen green, Popcorn gold, Fire red — with matching backgrounds
- **Warm micro-copy:** 12 new `AppText` constants with encouraging, nurturing tone

### 🖥️ Responsive AppShell (Phase 2)
- **Desktop (≥900px):** Fixed sidebar with logo, nav items, user card
- **Medium (600–899px):** Compact icon-only sidebar
- **Mobile (<600px):** Keep existing bottom navigation bar
- Migrated `MainTabsPage` from `BottomNavigationBar` → `AppShell` + `IndexedStack`

### 📊 Market Sentiment System (Phase 3)
- **Market sentiment strip** on market page: analyzes avg volatility across all A-share stocks
  - 🧘 佛系 (`<0.5%`) — calm waters, take your time
  - 🍿 吃瓜看戏 (`0.5–2.0%`) — mild swings, market seeking direction
  - 🔥 上头 (`>2.0%`) — high volatility, watch and wait
- **User emotion card** on assets page: based on 7-day trade frequency
- **`MarketSentimentService`** (ChangeNotifier): centralized sentiment computation

### 📱 Page Layout Upgrades (Phase 2)
- **Market page:** Responsive 2-column grid on desktop, sentiment strip, warm empty states
- **Assets page:** Two-column desktop layout with emotion card, equity curve, allocation card
- **Trade page:** Centered 480px form on desktop, warm SnackBar with gold border
- **Profile page:** Warm card styling for achievements + menu, Scaffold removed (AppShell provides it)
- **Leaderboard / Battle:** Removed Scaffold+AppBar → inline headers with warm style

### ✨ Micro-interactions (Phase 5)
- **HoverCard widget:** Golden border + 2px lift animation on mouse hover
- Stock cards, holding cards wrapped in `HoverCard`
- Sidebar nav items show pointer cursor on web

### 🧹 Code Quality
- Removed 35 lines of duplicate local color constants across 8 files
- Centralized all design tokens in `lib/core/constants.dart`
- Zero errors, zero warnings on `dart analyze`

### 📦 New Files
```
lib/presentation/widgets/app_shell.dart
lib/presentation/widgets/hover_card.dart
lib/domain/services/market_sentiment_service.dart
docs/superpowers/plans/2026-06-02-ui-warm-redesign.md
```

---

## M7 — Core Features (2026-05-30)

### 📈 Market Page 3-Tab Redesign
- **Watchlist (★):** Star-toggle stocks, Hive persistence, login sync
- **Holdings:** Real-time P&L calculation from position × daily change
- **Hot:** Top 20 by absolute volatility
- Guests default to Hot, logged-in users default to Watchlist

### 💰 Assets Page Polish
- USD → RMB (¥) currency display
- Hardcoded dark theme → `AppColors` warm theme
- Live todayPnL from holdings × daily change
- "USDT" → "现金", "估值以人民币计价"

### 🏅 Achievement System
- 10 achievements: 新手交易员 → 股神降临
- `AchievementService` + Hive persistence
- Profile achievement wall (unlocked/locked dual state)
- Auto-check after trade + unlock celebration dialog
- Hive box opened on app init (fix)

### 📚 Tutorial System
- 7-chapter PageView tutorial
- Progress dot indicator, prev/next/done buttons
- "学业有成" achievement on completion
- Entry from profile menu

### 🎭 Emotion Dashboard
- Emotion label at top of assets page
- 🧘 佛系 (≤1 trade) / 🍿 吃瓜 (2–5) / 🔥 上头 (≥6)
- Auto-calculated from 7-day trade frequency

### 📤 Share Card
- 350×500 performance card with RepaintBoundary → PNG
- Via share_plus: total assets, return rate, branding

### 🐛 Fixes
- Lazy-start CryptoService (only when user switches to crypto tab)
- Defensive parsing + per-coin error isolation in CryptoService
- Parse Binance string numeric values in CryptoService
- Open achievements Hive box on app init

---

## M1–M6 (2026-05 ~ earlier)

Core foundation:
- Flutter 3.x + Provider + Material 3
- Supabase Auth with virtual email (SHA-256 hash prefix)
- A-share market data via East Money API
- Hive local persistence for careers, trade history, watchlist
- Bottom tab navigation: 行情 / 资产 / 交易 / 个人
- Trade order form with buy/sell, quick position, estimate row
- Guest mode with local-only data
- Onboarding dialog + risk disclaimer
- Vercel deployment at https://darktrade.vercel.app
