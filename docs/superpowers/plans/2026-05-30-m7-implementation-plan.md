# M7 Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement M7 milestone features: three-tab market page with watchlist, asset page polish, achievement badges, tutorial system, emotion dashboard, and share card export.

**Architecture:** Follow existing patterns — Repository interface → Hive local + Supabase remote implementations → ChangeNotifier Service → Provider injection. Market page refactored from single list to three-tab IndexedStack. New WatchlistService, AchievementService, TutorialService added as ChangeNotifiers.

**Tech Stack:** Flutter 3.41 · Provider · Hive · Supabase · share_plus · Google Fonts

---

## File Structure

### New files:
```
lib/domain/services/watchlist_service.dart          # Watchlist ChangeNotifier
lib/data/repositories/watchlist_repository.dart      # Interface + Hive + Supabase
lib/domain/services/achievement_service.dart         # Achievement checker + state
lib/domain/models/achievement.dart                   # Achievement data class
lib/presentation/pages/tutorial/tutorial_page.dart   # Tutorial chapter viewer
lib/presentation/widgets/share_card.dart             # Share card widget
```

### Modified files:
```
lib/data/local/hive_service.dart                     # Register watchlist box
lib/main.dart                                        # Register new services
lib/presentation/pages/market/market_page.dart        # Refactor → three tabs
lib/presentation/pages/assets/assets_page.dart        # RMB + theme fix + today PnL
lib/presentation/pages/profile/profile_page.dart      # Add achievement section
```

---

### Task 1: WatchlistRepository — Interface + Hive Implementation

**Files:**
- Create: `lib/data/repositories/watchlist_repository.dart`

- [ ] **Step 1: Write the interface and Hive implementation**

```dart
// lib/data/repositories/watchlist_repository.dart
import 'package:hive/hive.dart';

abstract class WatchlistRepository {
  Future<List<String>> getWatchedSymbols();
  Future<void> addSymbol(String symbol);
  Future<void> removeSymbol(String symbol);
  Future<bool> isWatched(String symbol);
  Future<void> clear();
}

class HiveWatchlistRepo implements WatchlistRepository {
  static const _boxName = 'watchlist';
  static const _guestKey = '_guest_';

  Box<List> get _box => Hive.box<List>(_boxName);

  String _key(String? userId) => userId ?? _guestKey;

  @override
  Future<List<String>> getWatchedSymbols({String? userId}) async {
    final list = _box.get(_key(userId));
    if (list == null) return [];
    return list.cast<String>();
  }

  @override
  Future<void> addSymbol(String symbol, {String? userId}) async {
    final list = await getWatchedSymbols(userId: userId);
    if (!list.contains(symbol)) {
      list.add(symbol);
      await _box.put(_key(userId), list);
    }
  }

  @override
  Future<void> removeSymbol(String symbol, {String? userId}) async {
    final list = await getWatchedSymbols(userId: userId);
    list.remove(symbol);
    await _box.put(_key(userId), list);
  }

  @override
  Future<bool> isWatched(String symbol, {String? userId}) async {
    final list = await getWatchedSymbols(userId: userId);
    return list.contains(symbol);
  }

  @override
  Future<void> clear({String? userId}) async {
    await _box.delete(_key(userId));
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/repositories/watchlist_repository.dart
git commit -m "feat: add WatchlistRepository interface and Hive implementation"
```

---

### Task 2: Register watchlist Hive box

**Files:**
- Modify: `lib/data/local/hive_service.dart`

- [ ] **Step 1: Read current HiveService to find box registrations**

- [ ] **Step 2: Add watchlist box registration**

Add `Hive.registerAdapter` call or open the box. Find the `init()` method and add:

```dart
// In HiveService.init(), after existing box openings:
await Hive.openBox<List>('watchlist');
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/local/hive_service.dart
git commit -m "feat: register watchlist Hive box"
```

---

### Task 3: WatchlistService

**Files:**
- Create: `lib/domain/services/watchlist_service.dart`

- [ ] **Step 1: Write WatchlistService**

```dart
// lib/domain/services/watchlist_service.dart
import 'package:flutter/foundation.dart';
import 'package:dark_trade_app/data/repositories/watchlist_repository.dart';

class WatchlistService extends ChangeNotifier {
  final HiveWatchlistRepo _localRepo;
  List<String> _symbols = [];
  String? _userId;

  WatchlistService({required HiveWatchlistRepo localRepo})
      : _localRepo = localRepo;

  List<String> get symbols => List.unmodifiable(_symbols);

  Future<void> load({String? userId}) async {
    _userId = userId;
    _symbols = await _localRepo.getWatchedSymbols(userId: userId);
    notifyListeners();
  }

  bool isWatched(String symbol) => _symbols.contains(symbol);

  Future<void> toggleWatch(String symbol) async {
    if (_symbols.contains(symbol)) {
      _symbols.remove(symbol);
      await _localRepo.removeSymbol(symbol, userId: _userId);
    } else {
      _symbols.add(symbol);
      await _localRepo.addSymbol(symbol, userId: _userId);
    }
    notifyListeners();
  }

  /// Called on login — reload from remote/Supabase
  Future<void> onLogin(String userId) async {
    await load(userId: userId);
  }

  /// Called on logout — clear in-memory, keep guest local
  Future<void> onLogout() async {
    _userId = null;
    await load(); // reload guest data
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/services/watchlist_service.dart
git commit -m "feat: add WatchlistService with toggle and login/logout support"
```

---

### Task 4: Register WatchlistService in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add import and provider registration**

Add import at top:
```dart
import 'package:dark_trade_app/data/repositories/watchlist_repository.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';
```

Add after existing service creations:
```dart
final watchlistRepo = HiveWatchlistRepo();
final watchlistService = WatchlistService(localRepo: watchlistRepo)..load();
```

Add to MultiProvider:
```dart
ChangeNotifierProvider.value(value: watchlistService),
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: register WatchlistService in provider tree"
```

---

### Task 5: Refactor MarketPage — Three-Tab Structure

**Files:**
- Modify: `lib/presentation/pages/market/market_page.dart`

This is the largest task. We replace the current single-list market page with a three-tab design.

- [ ] **Step 1: Rewrite MarketExplorerWidget build method**

Replace the entire file content. Key changes:
1. Replace category chips with three tabs
2. Replace single StockList with IndexedStack of three lists
3. Add star toggle on each stock card
4. Guest mode defaults to Hot tab, logged-in defaults to Watchlist

```dart
// lib/presentation/pages/market/market_page.dart
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/presentation/pages/market/stock_detail_page.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Tab enum
// ---------------------------------------------------------------------------

enum MarketTab { watchlist, holdings, hot }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MarketExplorerWidget extends StatefulWidget {
  const MarketExplorerWidget({super.key});

  @override
  State<MarketExplorerWidget> createState() => _MarketExplorerWidgetState();
}

class _MarketExplorerWidgetState extends State<MarketExplorerWidget>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ---- theme colors -------------------------------------------------------
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---- helpers -------------------------------------------------------------

  String? _sectorFor(StockQuote q) {
    if (q.marketType == MarketType.aShare) {
      return AShareService.sectorForCode(q.symbol);
    }
    return null;
  }

  List<StockQuote> _topHot(List<StockQuote> quotes, {int count = 20}) {
    final sorted = List<StockQuote>.from(quotes);
    sorted.sort((a, b) => (b.changePercent ?? 0).abs().compareTo((a.changePercent ?? 0).abs()));
    return sorted.take(count).toList();
  }

  int _getInitialTab(AuthService auth, WatchlistService watchlist) {
    if (auth.isLoggedIn && watchlist.symbols.isNotEmpty) return 0; // watchlist
    return 2; // hot
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final aShare = context.watch<AShareService>();
    final watchlist = context.watch<WatchlistService>();
    final portfolio = context.watch<PortfolioService>();
    final auth = context.watch<AuthService>();

    // Set initial tab based on auth state (once)
    if (_tabController.index == 0 && !auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(2);
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            _buildSearchBar(),
            _buildDelayNote(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWatchlistTab(watchlist, aShare),
                  _buildHoldingsTab(portfolio, aShare),
                  _buildHotTab(aShare),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- header --------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 48, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '行情',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26, fontWeight: FontWeight.bold, color: _textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('实时', style: GoogleFonts.notoSansSc(
                  fontSize: 12, color: _textSecondary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- tab bar -------------------------------------------------------------

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _amber,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: GoogleFonts.notoSansSc(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '⭐ 关注'),
          Tab(text: '📦 持仓'),
          Tab(text: '🔥 热门'),
        ],
      ),
    );
  }

  // ---- search bar ----------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.notoSansSc(fontSize: 13, color: _textPrimary),
          decoration: InputDecoration(
            hintText: '搜索股票代码或名称...',
            hintStyle: GoogleFonts.notoSansSc(fontSize: 13, color: _textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 18),
            filled: true,
            fillColor: _cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _amber, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDelayNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        AppText.dataDelayNote,
        style: const TextStyle(color: _textMuted, fontSize: 11),
      ),
    );
  }

  // ---- Tab 1: Watchlist ----------------------------------------------------

  Widget _buildWatchlistTab(WatchlistService watchlist, AShareService aShare) {
    final quotes = aShare.quotes
        .where((q) => watchlist.isWatched(q.symbol))
        .toList();

    // Apply search filter
    final filtered = _searchQuery.isEmpty
        ? quotes
        : quotes.where((q) =>
            q.symbol.toLowerCase().contains(_searchQuery) ||
            q.name.toLowerCase().contains(_searchQuery)).toList();

    if (aShare.quotes.isEmpty) {
      return _loadingOrError(aShare);
    }

    if (watchlist.symbols.isEmpty) {
      return _emptyState('还没有关注股票', '去 🔥热门 发现感兴趣的股票，点击 ☆ 加入关注');
    }

    return _buildStockListView(filtered, showStar: true, isWatchedSet: watchlist.symbols.toSet());
  }

  // ---- Tab 2: Holdings -----------------------------------------------------

  Widget _buildHoldingsTab(PortfolioService portfolio, AShareService aShare) {
    if (portfolio.holdings.isEmpty) {
      return _emptyState('还没有持仓', '前往交易页开始你的第一笔模拟交易吧');
    }

    final priceMap = <String, double>{};
    for (final q in aShare.quotes) {
      priceMap[q.symbol] = q.price;
    }

    // Build synthetic StockQuote-like display from holdings
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: portfolio.holdings.length,
      itemBuilder: (context, i) {
        final h = portfolio.holdings[i];
        final livePrice = priceMap[h.symbol] ?? h.lastKnownPrice;
        final costPrice = h.averageCost;
        final pnl = (livePrice - costPrice) * h.amount;
        final pnlPercent = costPrice > 0 ? ((livePrice - costPrice) / costPrice * 100) : 0.0;
        final isUp = pnl >= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(h.symbol, style: GoogleFonts.notoSansSc(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary,
                        )),
                        const SizedBox(width: 8),
                        Text(h.name, style: GoogleFonts.notoSansSc(
                          fontSize: 12, color: _textSecondary,
                        )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('持有 ${h.amount.toStringAsFixed(0)}股 · 成本 ¥${costPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.notoSansSc(fontSize: 11, color: _textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('¥${livePrice.toStringAsFixed(2)}',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary,
                    )),
                  Text(
                    '${isUp ? "+" : ""}${pnl.toStringAsFixed(2)} (${isUp ? "+" : ""}${pnlPercent.toStringAsFixed(1)}%)',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isUp ? _green : _red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- Tab 3: Hot ----------------------------------------------------------

  Widget _buildHotTab(AShareService aShare) {
    final hot = _topHot(aShare.quotes);
    final filtered = _searchQuery.isEmpty
        ? hot
        : hot.where((q) =>
            q.symbol.toLowerCase().contains(_searchQuery) ||
            q.name.toLowerCase().contains(_searchQuery)).toList();

    if (aShare.quotes.isEmpty) {
      return _loadingOrError(aShare);
    }

    final watchlist = context.watch<WatchlistService>();
    return _buildStockListView(filtered, showStar: true, isWatchedSet: watchlist.symbols.toSet());
  }

  // ---- shared stock list ---------------------------------------------------

  Widget _buildStockListView(List<StockQuote> quotes, {bool showStar = false, Set<String>? isWatchedSet}) {
    if (quotes.isEmpty) {
      return _emptyState('没有匹配结果', '试试其他搜索词');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 60),
      itemCount: quotes.length,
      itemBuilder: (context, i) => _buildStockCard(quotes[i], showStar: showStar, isWatched: isWatchedSet?.contains(quotes[i].symbol) ?? false),
    );
  }

  Widget _buildStockCard(StockQuote row, {bool showStar = false, bool isWatched = false}) {
    final isUp = row.isUp;
    final changeColor = isUp ? _green : _red;
    final changeBg = isUp ? _greenBg : _redBg;
    final sector = _sectorFor(row);

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => StockDetailPage(quote: row))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Left: symbol + name + sector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(row.symbol, style: GoogleFonts.notoSansSc(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary,
                      )),
                      if (sector != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _chipBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(sector, style: GoogleFonts.notoSansSc(
                            fontSize: 9, color: _amber, fontWeight: FontWeight.w600,
                          )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(row.name, style: GoogleFonts.notoSansSc(
                    fontSize: 12, color: _textSecondary,
                  )),
                ],
              ),
            ),
            // Right: price + change + star
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(row.priceLabel, style: GoogleFonts.notoSansSc(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary,
                )),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: changeBg, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isUp ? "▲" : "▼"} ${row.changeLabel}',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 11, fontWeight: FontWeight.w700, color: changeColor,
                    ),
                  ),
                ),
              ],
            ),
            if (showStar) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.read<WatchlistService>().toggleWatch(row.symbol),
                child: Icon(
                  isWatched ? Icons.star : Icons.star_border,
                  color: isWatched ? _amber : _textMuted,
                  size: 22,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- shared states -------------------------------------------------------

  Widget _loadingOrError(AShareService aShare) {
    if (aShare.lastError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: _textMuted),
            const SizedBox(height: 12),
            Text(aShare.lastError!, textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSc(fontSize: 14, color: _textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => aShare.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: _amber));
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: _textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.notoSansSc(
            fontSize: 16, fontWeight: FontWeight.w600, color: _textSecondary,
          )),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.notoSansSc(
            fontSize: 13, color: _textMuted,
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Build and verify**

```bash
flutter build web --release
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/market/market_page.dart
git commit -m "feat: refactor market page to three-tab (watchlist/holdings/hot)"
```

---

### Task 6: Wire WatchlistService on Login/Logout

**Files:**
- Modify: `lib/domain/services/auth_service.dart` — call watchlistService.onLogin/onLogout
- Modify: `lib/main.dart` — pass watchlistService reference

- [ ] **Step 1: Connect AuthService ↔ WatchlistService**

In the auth service's login success path, after setting remote repos, notify watchlist:

In `lib/domain/services/auth_service.dart`, add a `WatchlistService?` field that gets set from main.dart:

```dart
// In AuthService class:
WatchlistService? _watchlistService;

void setWatchlistService(WatchlistService service) {
  _watchlistService = service;
}

// In the login success handler, after setRemoteRepo calls:
Future<void> _onLoginSuccess(User user) async {
  // ... existing code ...
  _watchlistService?.onLogin(user.id);
}

// In logout:
Future<void> logout() async {
  // ... existing code ...
  _watchlistService?.onLogout();
}
```

In `main.dart`, after creating services:
```dart
final authService = AuthService();
authService.setWatchlistService(watchlistService);
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/services/auth_service.dart lib/main.dart
git commit -m "feat: wire WatchlistService login/logout sync"
```

---

### Task 7: Asset Page — RMB Currency + Theme Fix

**Files:**
- Modify: `lib/presentation/pages/assets/assets_page.dart`

- [ ] **Step 1: Fix currency and theme colors**

Replace `_formatUsd` with `_formatRmb`, fix hardcoded colors to use AppColors, fix todayPnl:

```dart
// Replace _formatUsd with:
static String _formatRmb(double v) {
  final s = v.toStringAsFixed(2);
  final dot = s.indexOf('.');
  var whole = s.substring(0, dot);
  final frac = s.substring(dot);
  final neg = whole.startsWith('-');
  if (neg) whole = whole.substring(1);
  final buf = StringBuffer();
  if (neg) buf.write('-');
  buf.write('¥');
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  buf.write(frac);
  return buf.toString();
}

// Replace _white (Color(0xFF3D3025)) usage with AppColors.textPrimary
// Replace _gold with AppColors.gold
// Replace _bg with AppColors.background
// Replace _muted with AppColors.textSecondary
// Replace dark backgrounds (#121212) with AppColors.surface (white)
```

- [ ] **Step 2: Compute real todayPnl**

```dart
// In build(), compute todayPnl from holdings * daily change
double todayPnl = 0;
for (final h in portfolio.holdings) {
  final quote = aShare.quotes.cast<StockQuote?>().firstWhere(
    (q) => q?.symbol == h.symbol,
    orElse: () => null,
  );
  if (quote != null) {
    todayPnl += h.amount * quote.change; // change is daily price diff
  }
}

// Pass to GainLossCard:
GainLossCard(
  career: activeCareer,
  todayPnl: todayPnl,
),
```

- [ ] **Step 3: Update text labels**

Change "总资产折合" → "总资产"
Change "估值以 USDT 计价" → "估值以人民币计价"
Change "USDT" in allocations → "现金"

- [ ] **Step 4: Build and verify**

```bash
flutter build web --release
```

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/assets/assets_page.dart
git commit -m "fix: asset page RMB currency, warm theme colors, real today PnL"
```

---

### Task 8: Achievement Data Model + Service

**Files:**
- Create: `lib/domain/models/achievement.dart`
- Create: `lib/domain/services/achievement_service.dart`

- [ ] **Step 1: Write Achievement model**

```dart
// lib/domain/models/achievement.dart
class Achievement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final AchievementCondition condition;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.condition,
    this.unlocked = false,
    this.unlockedAt,
  });
}

enum AchievementCondition {
  firstTrade,       // 完成第一笔交易
  firstProfit,      // 单笔盈利
  threeInARow,      // 连续3笔盈利
  tenThousand,      // 总资产 ≥ 10,000
  tenTradesDaily,   // 单日交易 ≥ 10笔
  diamondHands,     // 持仓 > 7天
  bottomFisher,     // 当日最低价买入
  topSeller,        // 当日最高价卖出
  tutorialComplete, // 完成全部教程
  stockGod,         // 总收益率 ≥ 50%
}
```

- [ ] **Step 2: Write AchievementService**

```dart
// lib/domain/services/achievement_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:dark_trade_app/domain/models/achievement.dart';

class AchievementService extends ChangeNotifier {
  static const _boxName = 'achievements';
  Box get _box => Hive.box(_boxName);

  final List<Achievement> _achievements = [];
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<Achievement> get unlocked => _achievements.where((a) => a.unlocked).toList();

  AchievementService() {
    _initAchievements();
  }

  void _initAchievements() {
    _achievements.addAll([
      Achievement(id: 'first_trade', name: '新手交易员', emoji: '🍼', description: '完成第一笔交易', condition: AchievementCondition.firstTrade),
      Achievement(id: 'first_profit', name: '首次盈利', emoji: '🎯', description: '单笔交易盈利', condition: AchievementCondition.firstProfit),
      Achievement(id: 'three_row', name: '连赢三把', emoji: '📈', description: '连续3笔交易盈利', condition: AchievementCondition.threeInARow),
      Achievement(id: 'ten_thousand', name: '万元户', emoji: '💰', description: '总资产突破 ¥10,000', condition: AchievementCondition.tenThousand),
      Achievement(id: 'ten_trades', name: '交易狂热', emoji: '🔥', description: '单日交易 ≥ 10笔', condition: AchievementCondition.tenTradesDaily),
      Achievement(id: 'diamond', name: '钻石手', emoji: '💎', description: '持仓超过7天', condition: AchievementCondition.diamondHands),
      Achievement(id: 'bottom_fish', name: '抄底王', emoji: '🦈', description: '当日最低价买入', condition: AchievementCondition.bottomFisher),
      Achievement(id: 'top_seller', name: '逃顶高手', emoji: '🚀', description: '当日最高价卖出', condition: AchievementCondition.topSeller),
      Achievement(id: 'tutorial', name: '学业有成', emoji: '🎓', description: '完成全部7章教程', condition: AchievementCondition.tutorialComplete),
      Achievement(id: 'stock_god', name: '股神降临', emoji: '👑', description: '总收益率 ≥ 50%', condition: AchievementCondition.stockGod),
    ]);
    _loadState();
  }

  void _loadState() {
    for (final a in _achievements) {
      final unlocked = _box.get(a.id, defaultValue: false) as bool;
      a.unlocked = unlocked;
    }
  }

  void unlock(String id) {
    final a = _achievements.firstWhere((a) => a.id == id);
    if (!a.unlocked) {
      a.unlocked = true;
      a.unlockedAt = DateTime.now();
      _box.put(id, true);
      notifyListeners();
    }
  }

  /// Called after each trade to check conditions
  void checkAfterTrade({
    required int totalTrades,
    required int consecutiveWins,
    required double totalReturn,
    required double totalAssets,
    required int todayTradeCount,
  }) {
    if (totalTrades >= 1) unlock('first_trade');
    if (consecutiveWins >= 1) unlock('first_profit');
    if (consecutiveWins >= 3) unlock('three_row');
    if (totalAssets >= 10000) unlock('ten_thousand');
    if (todayTradeCount >= 10) unlock('ten_trades');
    if (totalReturn >= 0.50) unlock('stock_god');
  }

  void checkDiamondHands(int maxHoldDays) {
    if (maxHoldDays > 7) unlock('diamond');
  }

  void checkTutorialComplete() {
    unlock('tutorial');
  }
}
```

- [ ] **Step 3: Register in main.dart**

```dart
import 'package:dark_trade_app/domain/services/achievement_service.dart';

final achievementService = AchievementService();

// In MultiProvider:
ChangeNotifierProvider.value(value: achievementService),
```

- [ ] **Step 4: Commit**

```bash
git add lib/domain/models/achievement.dart lib/domain/services/achievement_service.dart lib/main.dart
git commit -m "feat: add achievement system with 10 badges"
```

---

### Task 9: Achievement Wall in Profile Page

**Files:**
- Modify: `lib/presentation/pages/profile/profile_page.dart`

- [ ] **Step 1: Add achievement section to profile**

Add a new section after the career summary card:

```dart
// After career section card, add:
const SizedBox(height: 12),
_buildAchievementSection(context),
```

- [ ] **Step 2: Implement achievement section builder**

```dart
Widget _buildAchievementSection(BuildContext context) {
  final achievementService = context.watch<AchievementService>();
  final achievements = achievementService.achievements;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('成就勋章', style: TextStyle(
          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
        )),
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
                    color: unlocked ? AppColors.gold.withValues(alpha: 0.1) : AppColors.unselectedBg,
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
                Text(
                  a.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: unlocked ? AppColors.textPrimary : AppColors.unselectedText,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Build and verify**

```bash
flutter build web --release
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/profile/profile_page.dart
git commit -m "feat: add achievement wall to profile page"
```

---

### Task 10: Tutorial Page

**Files:**
- Create: `lib/presentation/pages/tutorial/tutorial_page.dart`

- [ ] **Step 1: Write TutorialPage**

```dart
// lib/presentation/pages/tutorial/tutorial_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/domain/services/achievement_service.dart';
import 'package:provider/provider.dart';

class TutorialChapter {
  final int index;
  final String title;
  final String emoji;
  final String content;

  const TutorialChapter({
    required this.index,
    required this.title,
    required this.emoji,
    required this.content,
  });
}

const kTutorialChapters = [
  TutorialChapter(index: 1, title: '欢迎来到A股', emoji: '🇨🇳', content: 'A股是中国大陆的股票市场，在上海和深圳交易所交易。\n\n交易时间：周一至周五 9:30-11:30, 13:00-15:00\n\n重要规则：T+1 制度——当天买入的股票，最早下一个交易日才能卖出。'),
  TutorialChapter(index: 2, title: '看懂K线图', emoji: '📊', content: 'K线图是股票走势的可视化表示。\n\n• 红色（阳线）：收盘价高于开盘价，代表上涨\n• 绿色（阴线）：收盘价低于开盘价，代表下跌\n• 每根K线代表一个时间周期（日K、周K等）\n\n影线表示该周期内的最高价和最低价。'),
  TutorialChapter(index: 3, title: '限价单 vs 市价单', emoji: '📝', content: '限价单：指定你愿意买入/卖出的价格。只有市场价格达到你的要求才会成交。适合控制成本。\n\n市价单：以当前市场价格立即成交。速度快但可能价格不理想。\n\n新手建议先用限价单练习。'),
  TutorialChapter(index: 4, title: '建立第一个持仓', emoji: '🛒', content: '1. 在行情页浏览或搜索感兴趣的股票\n2. 点击股票查看K线详情\n3. 点击"去交易"进入下单页\n4. 选择买入、输入数量和价格\n5. 确认下单\n\n建议先用小额资金练习，熟悉流程。'),
  TutorialChapter(index: 5, title: '何时卖出', emoji: '💡', content: '止盈：设定一个盈利目标（如 +10%），达到后卖出锁利。\n\n止损：设定一个亏损底线（如 -5%），跌破后卖出控制风险。\n\n持仓管理：不要把所有资金集中在一只股票上，分散风险。'),
  TutorialChapter(index: 6, title: '读懂市场情绪', emoji: '🌡️', content: '行情页的市场情绪指标反映了整体市场的涨跌比。\n\n• 上涨股票多 → 市场偏乐观\n• 下跌股票多 → 市场偏恐慌\n\n关注热门板块和成交量变化，判断资金流向。\n\n不要盲目跟风，保持自己的判断。'),
  TutorialChapter(index: 7, title: '进阶技巧', emoji: '🎯', content: '风险控制三原则：\n1. 永远不要投入超过你能承受亏损的金额\n2. 设置止盈止损并严格执行\n3. 持续学习，记录每笔交易的心得\n\n常见新手错误：\n• 追涨杀跌——在高位追入，低位恐慌卖出\n• 过度交易——频繁买卖增加手续费成本\n• 不设止损——亏损不断扩大不愿止损'),
];

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('新手教程', style: GoogleFonts.notoSansSc(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.gold),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('跳过', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) {
                final isActive = i == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive ? AppColors.gold : AppColors.border,
                  ),
                );
              }),
            ),
          ),
          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: 7,
              itemBuilder: (context, i) {
                final ch = kTutorialChapters[i];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(ch.emoji, style: const TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(ch.title, style: GoogleFonts.notoSansSc(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                      )),
                      const SizedBox(height: 20),
                      Text(ch.content, style: GoogleFonts.notoSansSc(
                        fontSize: 15, color: AppColors.textSecondary, height: 1.8,
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bottom nav
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: const Text('← 上一页', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  const SizedBox.shrink(),
                if (_currentPage < 6)
                  ElevatedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('下一页 →'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context.read<AchievementService>().checkTutorialComplete();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('完成 🎉'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add tutorial entry in profile page menu**

In `profile_page.dart`, add menu item:
```dart
_menuItem('新手教程', Icons.school, () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialPage()));
}),
```

- [ ] **Step 3: Build and verify**

```bash
flutter build web --release
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/tutorial/tutorial_page.dart lib/presentation/pages/profile/profile_page.dart
git commit -m "feat: add 7-chapter tutorial system with PageView"
```

---

### Task 11: Emotion Indicator on Asset Page

**Files:**
- Modify: `lib/presentation/pages/assets/assets_page.dart`

- [ ] **Step 1: Add emotion badge at top of asset page**

After the "总资产" section, add an emotion chip:

```dart
// Compute emotion from trade history
String _emotionLabel(int recentTradeCount) {
  if (recentTradeCount <= 1) return '🧘 佛系';
  if (recentTradeCount <= 5) return '🍿 吃瓜';
  return '🔥 上头';
}

String _emotionHint(int recentTradeCount) {
  if (recentTradeCount <= 1) return '淡定持有，心如止水';
  if (recentTradeCount <= 5) return '观望中，吃瓜看戏';
  return '交易频繁，注意休息';
}

// In build(), add after GainLossCard:
// Get recent 7-day trade count from TradeHistoryService
final tradeHistory = context.watch<TradeHistoryService>();
final recentTrades = tradeHistory.records
    .where((r) => r.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7))))
    .length;

// Add emotion chip:
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emotionLabel(recentTrades), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(_emotionHint(recentTrades), style: GoogleFonts.notoSansSc(
            fontSize: 12, color: AppColors.textSecondary,
          )),
        ],
      ),
    ),
  ),
),
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/assets/assets_page.dart
git commit -m "feat: add emotion indicator to asset page"
```

---

### Task 12: Share Card Export

**Files:**
- Create: `lib/presentation/widgets/share_card.dart`

- [ ] **Step 1: Check if share_plus is in pubspec.yaml, add if needed**

```bash
grep share_plus pubspec.yaml || flutter pub add share_plus
```

- [ ] **Step 2: Write ShareCard widget**

```dart
// lib/presentation/widgets/share_card.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/local/models/career.dart';

class ShareCard extends StatelessWidget {
  final Career career;
  final String username;

  const ShareCard({super.key, required this.career, required this.username});

  @override
  Widget build(BuildContext context) {
    final totalReturn = career.totalReturnPercent;
    final isUp = totalReturn >= 0;
    final equity = career.equityHistory;

    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFFFF3E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D4A8), width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('D', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Text('DarkTrade', style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
              )),
            ],
          ),
          // Main stats
          Column(
            children: [
              Text(username, style: GoogleFonts.notoSansSc(
                fontSize: 16, color: AppColors.textSecondary,
              )),
              const SizedBox(height: 8),
              Text(career.name, style: GoogleFonts.notoSansSc(
                fontSize: 14, color: AppColors.gold, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 20),
              Text('¥${career.totalEquity(0).toStringAsFixed(2)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isUp ? AppColors.upBg : AppColors.downBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isUp ? "+" : ""}${totalReturn.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: isUp ? AppColors.up : AppColors.down,
                  ),
                ),
              ),
            ],
          ),
          // Footer
          Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('QR', style: TextStyle(color: AppColors.textSecondary))),
              ),
              const SizedBox(height: 8),
              Text('扫描二维码体验 DarkTrade',
                style: GoogleFonts.notoSansSc(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(AppText.disclaimerFooter,
                style: const TextStyle(fontSize: 9, color: AppColors.unselectedText)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper to capture and share
Future<void> sharePerformanceCard(BuildContext context, Career career, String username) async {
  final key = GlobalKey();
  final widget = RepaintBoundary(
    key: key,
    child: ShareCard(career: career, username: username),
  );

  // Render offscreen
  final overlay = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -1000,
      child: Material(child: widget),
    ),
  );
  Overlay.of(context).insert(overlay);

  await Future.delayed(const Duration(milliseconds: 500));

  try {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        await Share.shareXFiles([XFile.fromData(bytes, name: 'darktrade_share.png')],
          text: '我在 DarkTrade 的模拟交易成绩，来一起练习吧！',
        );
      }
    }
  } finally {
    overlay.remove();
  }
}
```

- [ ] **Step 3: Add share button to asset page**

In `assets_page.dart`, add a share button near the top:
```dart
// After GainLossCard:
IconButton(
  onPressed: () => sharePerformanceCard(context, activeCareer!, auth.username ?? '交易员'),
  icon: const Icon(Icons.share, color: AppColors.gold),
)
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/share_card.dart lib/presentation/pages/assets/assets_page.dart
git commit -m "feat: add share card export with RepaintBoundary + share_plus"
```

---

### Task 13: Final Integration — Wire Achievement Checks

**Files:**
- Modify: `lib/domain/services/trade_history_service.dart` or the trade execution path

- [ ] **Step 1: Add achievement check after trade execution**

Find where trades are executed (CareerService or TradePage). After a trade completes:

```dart
// After trade execution completes:
final achievementService = /* get from context/provider */;
achievementService.checkAfterTrade(
  totalTrades: tradeHistory.records.length,
  consecutiveWins: _computeConsecutiveWins(tradeHistory.records),
  totalReturn: activeCareer.totalReturnPercent / 100,
  totalAssets: activeCareer.totalEquity(0),
  todayTradeCount: tradeHistory.records
      .where((r) => r.timestamp.day == DateTime.now().day)
      .length,
);
```

- [ ] **Step 2: Show unlock toast**

In a widget that listens to AchievementService, show a dialog when a new achievement unlocks:

```dart
// AchievementService - add:
String? _justUnlocked;
String? get justUnlocked => _justUnlocked;

void unlock(String id) {
  // ... existing unlock code ...
  _justUnlocked = id;
  notifyListeners();
}

void clearJustUnlocked() {
  _justUnlocked = null;
}
```

Then in profile or a root widget:
```dart
Consumer<AchievementService>(
  builder: (context, service, _) {
    if (service.justUnlocked != null) {
      final a = service.achievements.firstWhere((a) => a.id == service.justUnlocked);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('${a.emoji} 成就解锁！', style: const TextStyle(color: AppColors.gold)),
            content: Text('${a.name}\n${a.description}', style: const TextStyle(color: AppColors.textPrimary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('太棒了！', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        );
        service.clearJustUnlocked();
      });
    }
    return const SizedBox.shrink();
  },
),
```

- [ ] **Step 3: Build and verify**

```bash
flutter build web --release
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: wire achievement checks after trade + unlock toast"
```

---

## Verification Checklist

After all tasks complete, verify:
- [ ] `flutter build web --release` passes without errors
- [ ] Three tabs on market page render correctly
- [ ] Star toggle adds/removes from watchlist
- [ ] Holdings tab shows positions with live PnL
- [ ] Hot tab shows top 20 by volatility
- [ ] Asset page shows ¥ currency and correct theme
- [ ] Achievement wall visible in profile page
- [ ] Tutorial page navigates through 7 chapters
- [ ] Emotion badge shows correct label
- [ ] Share card renders and triggers share sheet
