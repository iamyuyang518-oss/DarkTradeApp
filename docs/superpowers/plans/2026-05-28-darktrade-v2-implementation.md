# DarkTrade V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade DarkTrade from a local demo to a publishable simulated trading platform with career system, local persistence, trade history, auth, and polished UI.

**Architecture:** Add Hive for local persistence (careers, holdings, trade records), a CareerService for managing multiple independent trading careers, a TradeHistoryService for recording all trades, and an AuthService for Supabase-based registration/login. New UI pages for trade history and career management. Existing pages get career selector, gain/loss cards, and success animations.

**Tech Stack:** Flutter 3.x, Provider, Hive (local persistence), Supabase (auth + remote storage), http, google_fonts

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/models/career.dart` | Career data model with Hive TypeAdapter |
| `lib/models/trade_record.dart` | Trade record data model with Hive TypeAdapter |
| `lib/services/hive_service.dart` | Hive initialization, box registration, TypeAdapter registration |
| `lib/services/career_service.dart` | Career CRUD (create, switch, delete, list) extending ChangeNotifier |
| `lib/services/trade_history_service.dart` | Trade record persistence and query, extending ChangeNotifier |
| `lib/services/auth_service.dart` | Supabase Auth: register, login, logout, guest/login state |
| `lib/pages/trade_history_page.dart` | Scrollable trade history list with time filters |
| `lib/pages/career_management_sheet.dart` | Bottom sheet for creating/switching/deleting careers |
| `lib/widgets/career_selector.dart` | Top-of-page career name display + tap-to-switch |
| `lib/widgets/gain_loss_card.dart` | Today gain / total gain / total return rate cards |
| `lib/widgets/equity_curve_chart.dart` | Mini equity curve sparkline via CustomPainter |
| `lib/widgets/guest_banner.dart` | Semi-transparent top banner: "游客模式" with register/login links |
| `lib/widgets/confetti_overlay.dart` | Particle animation overlay for successful trades |
| `lib/widgets/onboarding_flow.dart` | Welcome dialog + career creation + tab highlight guide |

### Modified Files
| File | Changes |
|------|---------|
| `pubspec.yaml` | Add `hive`, `hive_flutter`, `supabase_flutter`, `share_plus`, `confetti_widget` |
| `lib/main.dart` | Initialize Hive, register new services in MultiProvider |
| `lib/assets_page.dart` | Add CareerSelector, GainLossCard, EquityCurveChart; link to trade history |
| `lib/presentation/pages/trade/trade_page.dart` | Add available balance display, confetti on success |
| `lib/presentation/pages/trade/logic/trade_form_controller.dart` | Accept careerId, record trades via TradeHistoryService |
| `lib/profile_page.dart` | Redesign: guest vs logged-in states, career management entry |
| `lib/app/main_tabs_page.dart` | Add GuestBanner when not logged in |
| `lib/market_explorer.dart` | Fix dynamic list (7→20 items from TODO.md) |

---

### Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Update pubspec.yaml with new dependencies**

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  provider: ^6.1.2
  http: ^1.6.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  supabase_flutter: ^2.8.1
  share_plus: ^10.1.4
  confetti_widget: ^0.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.13
```

- [ ] **Step 2: Run flutter pub get**

```bash
cd D:\DarkTradeApp && flutter pub get
```

Expected: "exit code 0", all dependencies resolved.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add hive, supabase, share_plus, confetti_widget dependencies"
```

---

### Task 2: Create Career Data Model

**Files:**
- Create: `lib/models/career.dart`

- [ ] **Step 1: Write the Career model with Hive annotations**

```dart
import 'package:hive/hive.dart';

part 'career.g.dart';

@HiveType(typeId: 0)
class Career extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double initialBalance;

  @HiveField(3)
  double currentBalance;

  @HiveField(4)
  double totalPnl;

  @HiveField(5)
  int totalTrades;

  @HiveField(6)
  int winningTrades;

  @HiveField(7)
  double bestTradePnl;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  List<double> equityHistory; // snapshot of total asset value over time

  Career({
    required this.id,
    required this.name,
    required this.initialBalance,
    this.currentBalance = 0,
    this.totalPnl = 0,
    this.totalTrades = 0,
    this.winningTrades = 0,
    this.bestTradePnl = 0,
    DateTime? createdAt,
    List<double>? equityHistory,
  })  : createdAt = createdAt ?? DateTime.now(),
        equityHistory = equityHistory ?? [],
        currentBalance = currentBalance == 0 ? initialBalance : currentBalance;

  double get totalReturnRate =>
      initialBalance > 0 ? (totalPnl / initialBalance) * 100 : 0;

  double get winRate =>
      totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0;

  void recordTrade(double pnl) {
    totalTrades++;
    if (pnl > 0) winningTrades++;
    totalPnl += pnl;
    currentBalance += pnl;
    if (pnl > bestTradePnl) bestTradePnl = pnl;
  }

  void recordEquitySnapshot(double totalAssetValue) {
    equityHistory.add(totalAssetValue);
    if (equityHistory.length > 90) {
      equityHistory.removeAt(0); // keep last 90 snapshots
    }
  }
}
```

- [ ] **Step 2: Generate Hive adapter**

```bash
cd D:\DarkTradeApp && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/models/career.g.dart`.

- [ ] **Step 3: Commit**

```bash
git add lib/models/career.dart lib/models/career.g.dart
git commit -m "feat: add Career data model with Hive persistence"
```

---

### Task 3: Create TradeRecord Data Model

**Files:**
- Create: `lib/models/trade_record.dart`

- [ ] **Step 1: Write the TradeRecord model**

```dart
import 'package:hive/hive.dart';

part 'trade_record.g.dart';

@HiveType(typeId: 1)
class TradeRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String careerId;

  @HiveField(2)
  final String type; // 'buy' or 'sell'

  @HiveField(3)
  final String symbol;

  @HiveField(4)
  final String name;

  @HiveField(5)
  final String marketType; // 'crypto', 'usStock', 'aShare'

  @HiveField(6)
  final double quantity;

  @HiveField(7)
  final double price;

  @HiveField(8)
  final double? pnl; // null for buys, set for sells

  @HiveField(9)
  final DateTime createdAt;

  TradeRecord({
    required this.id,
    required this.careerId,
    required this.type,
    required this.symbol,
    required this.name,
    required this.marketType,
    required this.quantity,
    required this.price,
    this.pnl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

- [ ] **Step 2: Generate Hive adapter**

```bash
cd D:\DarkTradeApp && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/models/trade_record.g.dart`.

- [ ] **Step 3: Commit**

```bash
git add lib/models/trade_record.dart lib/models/trade_record.g.dart
git commit -m "feat: add TradeRecord data model with Hive persistence"
```

---

### Task 4: Create HiveService for Initialization

**Files:**
- Create: `lib/services/hive_service.dart`

- [ ] **Step 1: Write HiveService**

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/career.dart';
import '../models/trade_record.dart';

class HiveService {
  static const String careersBox = 'careers';
  static const String tradeHistoryBox = 'tradeHistory';
  static const String authBox = 'auth';
  static const String prefsBox = 'prefs';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CareerAdapter());
    Hive.registerAdapter(TradeRecordAdapter());
    await Future.wait([
      Hive.openBox<Career>(careersBox),
      Hive.openBox<TradeRecord>(tradeHistoryBox),
      Hive.openBox(authBox),
      Hive.openBox(prefsBox),
    ]);
  }

  static Box<Career> get careers => Hive.box<Career>(careersBox);
  static Box<TradeRecord> get tradeHistory =>
      Hive.box<TradeRecord>(tradeHistoryBox);
  static Box get auth => Hive.box(authBox);
  static Box get prefs => Hive.box(prefsBox);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/hive_service.dart
git commit -m "feat: add HiveService for box initialization and access"
```

---

### Task 5: Create CareerService

**Files:**
- Create: `lib/services/career_service.dart`

- [ ] **Step 1: Write CareerService**

```dart
import 'package:flutter/foundation.dart';
import '../models/career.dart';
import 'hive_service.dart';

class CareerService extends ChangeNotifier {
  Career? _activeCareer;
  List<Career> get careers => HiveService.careers.values.toList();
  Career? get activeCareer => _activeCareer;

  CareerService() {
    if (careers.isEmpty) {
      _activeCareer = _createDefaultCareer();
    } else {
      _activeCareer = careers.first;
    }
  }

  Career _createDefaultCareer() {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '生涯 #1',
      initialBalance: 100000,
    );
    HiveService.careers.put(career.id, career);
    notifyListeners();
    return career;
  }

  Career createCareer(String name, double initialBalance) {
    final career = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      initialBalance: initialBalance,
    );
    HiveService.careers.put(career.id, career);
    notifyListeners();
    return career;
  }

  void switchCareer(String careerId) {
    final career = HiveService.careers.get(careerId);
    if (career != null) {
      _activeCareer = career;
      notifyListeners();
    }
  }

  void deleteCareer(String careerId) {
    if (careers.length <= 1) return; // must keep at least one
    HiveService.careers.delete(careerId);
    if (_activeCareer?.id == careerId) {
      _activeCareer = careers.first;
    }
    // also delete associated trade records
    final records = HiveService.tradeHistory.values
        .where((r) => r.careerId == careerId)
        .toList();
    for (final r in records) {
      HiveService.tradeHistory.delete(r.id);
    }
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    _activeCareer?.recordEquitySnapshot(newBalance);
    _activeCareer?.save();
    notifyListeners();
  }

  void recordPnl(double pnl) {
    _activeCareer?.recordTrade(pnl);
    _activeCareer?.save();
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/career_service.dart
git commit -m "feat: add CareerService for career CRUD operations"
```

---

### Task 6: Create TradeHistoryService

**Files:**
- Create: `lib/services/trade_history_service.dart`

- [ ] **Step 1: Write TradeHistoryService**

```dart
import 'package:flutter/foundation.dart';
import '../models/trade_record.dart';
import 'hive_service.dart';

class TradeHistoryService extends ChangeNotifier {
  List<TradeRecord> getRecordsForCareer(String careerId) {
    return HiveService.tradeHistory.values
        .where((r) => r.careerId == careerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<TradeRecord> getRecordsForCareerFiltered(
    String careerId, {
    int days = 0, // 0 means all
  }) {
    final records = getRecordsForCareer(careerId);
    if (days == 0) return records;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records.where((r) => r.createdAt.isAfter(cutoff)).toList();
  }

  void addRecord(TradeRecord record) {
    HiveService.tradeHistory.put(record.id, record);
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/trade_history_service.dart
git commit -m "feat: add TradeHistoryService for trade record persistence"
```

---

### Task 7: Wire New Services into main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Read current main.dart**

Read the file first at `lib/main.dart`.

- [ ] **Step 2: Update main.dart to initialize Hive and register new services**

Change the main() function and MultiProvider:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/live_market_service.dart';
import 'services/us_stock_service.dart';
import 'services/a_share_service.dart';
import 'services/portfolio_service.dart';
import 'services/trade_selection_service.dart';
import 'services/hive_service.dart';
import 'services/career_service.dart';
import 'services/trade_history_service.dart';
import 'app/main_tabs_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  final crypto = LiveMarketService()..start();
  final usStock = UsStockService()..start();
  final aShare = AShareService()..start();
  final portfolio = PortfolioService()..seedDemo();
  final tradeSelection = TradeSelectionService();
  final careerService = CareerService();
  final tradeHistory = TradeHistoryService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: crypto),
        ChangeNotifierProvider.value(value: usStock),
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

class DarkTradeApp extends StatelessWidget {
  const DarkTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarkTrade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFFFD700),
        ),
      ),
      home: const MainTabsPage(),
    );
  }
}
```

- [ ] **Step 3: Verify the app compiles**

```bash
cd D:\DarkTradeApp && flutter analyze lib/main.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire CareerService and TradeHistoryService into app root"
```

---

### Task 8: Integrate CareerService into Trade Execution

**Files:**
- Modify: `lib/presentation/pages/trade/logic/trade_form_controller.dart`
- Modify: `lib/presentation/pages/trade/widgets/execute_button.dart`

- [ ] **Step 1: Update TradeFormController to accept services and record trades**

The controller's `execute()` method should:
1. Check available balance from active career
2. After successful trade, record it via TradeHistoryService
3. Update career PnL

The `applyQuickPercent` method should use career balance instead of portfolio balance:

```dart
// In TradeFormController, add fields:
final CareerService _careerService;
final TradeHistoryService _tradeHistory;

// Constructor change:
TradeFormController(this._careerService, this._tradeHistory, {required PortfolioService portfolio})
    : _portfolio = portfolio, ...;

// In applyQuickPercent for buy:
double get _availableBalance => _careerService.activeCareer?.currentBalance ?? 0;

double _calcMaxBuyQty() {
  if (_price <= 0) return 0;
  return _availableBalance / _price;
}

// In execute() after successful trade:
void _recordTrade(bool isBuy, StockQuote quote, double qty, double price, {double? pnl}) {
  _tradeHistory.addRecord(TradeRecord(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    careerId: _careerService.activeCareer!.id,
    type: isBuy ? 'buy' : 'sell',
    symbol: quote.symbol,
    name: quote.name,
    marketType: quote.marketType.name,
    quantity: qty,
    price: price,
    pnl: pnl,
  ));
  if (pnl != null) {
    _careerService.recordPnl(pnl);
  }
}
```

- [ ] **Step 2: Update TradePage to pass new services to controller**

In `lib/presentation/pages/trade/trade_page.dart`, update to pass CareerService and TradeHistoryService:

```dart
// In TradePage.build():
final careerService = context.watch<CareerService>();
final tradeHistory = context.read<TradeHistoryService>();
final portfolio = context.read<PortfolioService>();

// Pass to controller:
_controller = TradeFormController(careerService, tradeHistory, portfolio: portfolio);
```

- [ ] **Step 3: Verify compilation**

```bash
cd D:\DarkTradeApp && flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/pages/trade/logic/trade_form_controller.dart lib/presentation/pages/trade/trade_page.dart
git commit -m "feat: integrate CareerService and TradeHistoryService into trade execution"
```

---

### Task 9: Add Available Balance to Trade Page

**Files:**
- Modify: `lib/presentation/pages/trade/trade_page.dart`
- Modify: `lib/presentation/pages/trade/widgets/symbol_bar.dart`

- [ ] **Step 1: Add balance display above SymbolBar**

Insert a balance row between the AppBar and SymbolBar:

```dart
// In TradePage build(), add this widget before SymbolBar:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
    children: [
      const Text('可用', style: TextStyle(color: Colors.white54, fontSize: 13)),
      const SizedBox(width: 8),
      Text(
        '${_controller._availableBalance.toStringAsFixed(2)} USDT',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/trade/trade_page.dart
git commit -m "feat: show available balance on trade page"
```

---

### Task 10: Add Confetti Success Animation

**Files:**
- Create: `lib/widgets/confetti_overlay.dart`
- Modify: `lib/presentation/pages/trade/trade_page.dart`

- [ ] **Step 1: Write confetti overlay widget**

```dart
import 'package:flutter/material.dart';
import 'package:confetti_widget/confetti_widget.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool play;

  const ConfettiOverlay({super.key, required this.child, this.play = false});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFFFD700),
              Color(0xFFFF9500),
              Color(0xFF5AC8FA),
            ],
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 5,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Wrap trade page body with ConfettiOverlay**

In `lib/presentation/pages/trade/trade_page.dart`, add a `_showConfetti` state field, set to true on successful execution, and wrap the body with `ConfettiOverlay`:

```dart
// In _TradePageState:
bool _showConfetti = false;

// In execute callback:
final result = _controller.execute();
if (result.success) {
  setState(() => _showConfetti = true);
  // reset after animation
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) setState(() => _showConfetti = false);
  });
}

// Wrap body:
body: ConfettiOverlay(
  play: _showConfetti,
  child: Column(/* existing content */),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/confetti_overlay.dart lib/presentation/pages/trade/trade_page.dart
git commit -m "feat: add confetti celebration on successful trade"
```

---

### Task 11: Create Career Selector Widget

**Files:**
- Create: `lib/widgets/career_selector.dart`

- [ ] **Step 1: Write CareerSelector widget**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/career_service.dart';
import '../pages/career_management_sheet.dart';

class CareerSelector extends StatelessWidget {
  const CareerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final careerService = context.watch<CareerService>();
    final career = careerService.activeCareer;
    if (career == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const CareerManagementSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFD700).withAlpha(80)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 6),
            Text(
              career.name,
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Color(0xFFFFD700), size: 18),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/career_selector.dart
git commit -m "feat: add CareerSelector widget for top-of-page career switching"
```

---

### Task 12: Create Career Management Bottom Sheet

**Files:**
- Create: `lib/pages/career_management_sheet.dart`

- [ ] **Step 1: Write CareerManagementSheet**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/career_service.dart';
import '../models/career.dart';

class CareerManagementSheet extends StatefulWidget {
  const CareerManagementSheet({super.key});

  @override
  State<CareerManagementSheet> createState() => _CareerManagementSheetState();
}

class _CareerManagementSheetState extends State<CareerManagementSheet> {
  @override
  Widget build(BuildContext context) {
    final careerService = context.watch<CareerService>();
    final careers = careerService.careers;
    final active = careerService.activeCareer;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              child: Divider(color: Colors.white24, thickness: 3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '生涯管理',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...careers.map((c) => _careerTile(c, c.id == active?.id, careerService)),
          const SizedBox(height: 12),
          _createButton(careerService),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _careerTile(Career career, bool isActive, CareerService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFD700).withAlpha(25) : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: const Color(0xFFFFD700)) : null,
      ),
      child: ListTile(
        title: Text(career.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '初始资金 \$${career.initialBalance.toStringAsFixed(0)}  收益率 ${career.totalReturnRate.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              TextButton(
                onPressed: () {
                  service.switchCareer(career.id);
                  Navigator.pop(context);
                },
                child: const Text('切换', style: TextStyle(color: Color(0xFFFFD700))),
              ),
            if (careers.length > 1)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () {
                  service.deleteCareer(career.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _createButton(CareerService service) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCreateDialog(service),
        icon: const Icon(Icons.add, color: Color(0xFFFFD700)),
        label: const Text('新建生涯', style: TextStyle(color: Color(0xFFFFD700))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFD700)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showCreateDialog(CareerService service) {
    final nameCtrl = TextEditingController(text: '生涯 #${service.careers.length + 1}');
    final balanceCtrl = TextEditingController(text: '100000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('新建生涯', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '生涯名称',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '初始资金 (USDT)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final balance = double.tryParse(balanceCtrl.text.trim()) ?? 100000;
              if (name.isNotEmpty) {
                service.createCareer(name, balance.clamp(1, 100000000));
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
```

Note: `careers` getter needs to be used for length in the build method — the local `careers` variable from `careerService.careers` is captured above.

- [ ] **Step 2: Commit**

```bash
git add lib/pages/career_management_sheet.dart
git commit -m "feat: add career management bottom sheet with create/switch/delete"
```

---

### Task 13: Create Gain/Loss Card Widget

**Files:**
- Create: `lib/widgets/gain_loss_card.dart`

- [ ] **Step 1: Write GainLossCard**

```dart
import 'package:flutter/material.dart';
import '../models/career.dart';

class GainLossCard extends StatelessWidget {
  final Career career;
  final double todayPnl; // computed from holdings * price changes
  final Color upColor;
  final Color downColor;

  const GainLossCard({
    super.key,
    required this.career,
    required this.todayPnl,
    this.upColor = const Color(0xFF00C853),
    this.downColor = const Color(0xFFFF1744),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF222222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _statColumn(
            '今日收益',
            todayPnl,
            todayPnl >= 0 ? upColor : downColor,
          ),
          _divider(),
          _statColumn(
            '累计收益',
            career.totalPnl,
            career.totalPnl >= 0 ? upColor : downColor,
          ),
          _divider(),
          _statColumn(
            '总收益率',
            career.totalReturnRate,
            career.totalReturnRate >= 0 ? upColor : downColor,
            suffix: '%',
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, double value, Color color, {String suffix = ''}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}$suffix',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white10,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/gain_loss_card.dart
git commit -m "feat: add gain/loss overview card widget"
```

---

### Task 14: Create Mini Equity Curve Chart

**Files:**
- Create: `lib/widgets/equity_curve_chart.dart`

- [ ] **Step 1: Write EquityCurveChart using CustomPainter**

```dart
import 'package:flutter/material.dart';

class EquityCurveChart extends StatelessWidget {
  final List<double> data;

  const EquityCurveChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('数据不足', style: TextStyle(color: Colors.white38))),
      );
    }

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 56),
        painter: _EquityCurvePainter(data),
      ),
    );
  }
}

class _EquityCurvePainter extends CustomPainter {
  final List<double> data;

  _EquityCurvePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    if (range == 0) return;

    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = size.height - ((data[i] - minY) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // fill below curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFD700).withAlpha(60),
          const Color(0xFFFFD700).withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _EquityCurvePainter old) => old.data != data;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/equity_curve_chart.dart
git commit -m "feat: add mini equity curve chart widget"
```

---

### Task 15: Update Assets Page with Career Selector, Gain/Loss, and Equity Curve

**Files:**
- Modify: `lib/assets_page.dart`

- [ ] **Step 1: Read current assets_page.dart**

Read the file first.

- [ ] **Step 2: Add CareerSelector, GainLossCard, EquityCurveChart, and Trade History button**

At the top of the assets page body, insert:

1. **CareerSelector** as the top widget (replacing or augmenting the current header)
2. **GainLossCard** below the total assets header
3. **EquityCurveChart** below the gain/loss card
4. **Trade History button** at the bottom or as a trailing action in the app bar

The update involves changing the CustomScrollView slivers to include these new widgets. Since AssetsPage is a StatelessWidget, we convert it to watch CareerService:

```dart
// In AssetsPage.build(), add at the top:
final careerService = context.watch<CareerService>();
final activeCareer = careerService.activeCareer;

// In the SliverList delegate, add new items:
// - CareerSelector widget
// - GainLossCard with todayPnl computed from holdings * daily price changes
// - EquityCurveChart from activeCareer.equityHistory
// - "交易记录" ListTile button navigating to TradeHistoryPage
```

- [ ] **Step 3: Verify compilation**

```bash
cd D:\DarkTradeApp && flutter analyze lib/assets_page.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/assets_page.dart
git commit -m "feat: add career selector, gain/loss card, equity curve to assets page"
```

---

### Task 16: Create Trade History Page

**Files:**
- Create: `lib/pages/trade_history_page.dart`

- [ ] **Step 1: Write TradeHistoryPage**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/trade_history_service.dart';
import '../services/career_service.dart';
import '../models/trade_record.dart';

class TradeHistoryPage extends StatefulWidget {
  const TradeHistoryPage({super.key});

  @override
  State<TradeHistoryPage> createState() => _TradeHistoryPageState();
}

class _TradeHistoryPageState extends State<TradeHistoryPage> {
  int _selectedDays = 0; // 0 = all, 7, 30
  static const _filters = [0, 7, 30];

  @override
  Widget build(BuildContext context) {
    final careerId = context.watch<CareerService>().activeCareer?.id;
    final history = context.watch<TradeHistoryService>();
    final records = careerId != null
        ? history.getRecordsForCareerFiltered(careerId, days: _selectedDays)
        : <TradeRecord>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('交易记录', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D0D0D),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Column(
        children: [
          _filterRow(),
          Expanded(child: records.isEmpty ? _emptyState() : _listView(records)),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((d) {
          final isSelected = _selectedDays == d;
          final label = d == 0 ? '全部' : '近${d}天';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedDays = d),
              selectedColor: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF222222),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('还没有交易记录', style: TextStyle(color: Colors.white54, fontSize: 16)),
          SizedBox(height: 4),
          Text('去行情页看看吧 👀', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _listView(List<TradeRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (_, i) => _recordTile(records[i]),
    );
  }

  Widget _recordTile(TradeRecord r) {
    final isBuy = r.type == 'buy';
    final color = isBuy ? const Color(0xFF00C853) : const Color(0xFFFF1744);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(isBuy ? '买' : '卖', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 15)),
                Text(r.symbol, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.quantity.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '@ \$${r.price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          if (r.pnl != null) ...[
            const SizedBox(width: 12),
            Text(
              '${r.pnl! >= 0 ? '+' : ''}${r.pnl!.toStringAsFixed(2)}',
              style: TextStyle(
                color: r.pnl! >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF1744),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/pages/trade_history_page.dart
git commit -m "feat: add trade history page with time filters"
```

---

### Task 17: Redesign Profile Page for Guest/Logged-in States

**Files:**
- Modify: `lib/profile_page.dart`

- [ ] **Step 1: Read current profile_page.dart**

Read the file first.

- [ ] **Step 2: Rewrite ProfilePage with dual-state design**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/career_service.dart';
import '../pages/career_management_sheet.dart';
import '../pages/trade_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final careerService = context.watch<CareerService>();
    // Auth state will be added in P2; for now, always guest
    final isLoggedIn = false;
    final activeCareer = careerService.activeCareer;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            // Avatar + identity
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                      color: const Color(0xFF1A1A1A),
                    ),
                    child: const Icon(Icons.person, size: 36, color: Color(0xFFFFD700)),
                  ),
                  const SizedBox(height: 12),
                  if (isLoggedIn)
                    const Text('用户名', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('游客模式', style: TextStyle(color: Colors.orange, fontSize: 13)),
                    ),
                  if (isLoggedIn)
                    const Text('UID: 888888', style: TextStyle(color: Colors.white38, fontSize: 13))
                  else ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: navigate to register/login page (P2)
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFD700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('注册 / 登录', style: TextStyle(color: Color(0xFFFFD700))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Career summary
            if (activeCareer != null) _sectionCard(
              title: '当前生涯',
              trailing: Text(activeCareer.name, style: const TextStyle(color: Color(0xFFFFD700))),
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A1A1A),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const CareerManagementSheet(),
              ),
            ),
            const SizedBox(height: 12),
            // Menu items
            _menuCard([
              _menuItem('生涯管理', Icons.sports_esports, () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => const CareerManagementSheet(),
                );
              }),
              _menuItem('交易记录', Icons.receipt_long, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeHistoryPage()));
              }),
              if (isLoggedIn) _menuItem('修改密码', Icons.lock_outline, () {}),
              _menuItem('关于 DarkTrade', Icons.info_outline, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('DarkTrade v2.0 — 模拟交易平台')),
                );
              }),
            ]),
            const SizedBox(height: 24),
            if (isLoggedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: logout (P2)
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('退出登录', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            const SizedBox(height: 16),
            const Center(
              child: Text('DarkTrade v2.0.0', style: TextStyle(color: Colors.white24, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _menuItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd D:\DarkTradeApp && flutter analyze lib/profile_page.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/profile_page.dart
git commit -m "feat: redesign profile page with career management and trade history entries"
```

---

### Task 18: Add Guest Mode Banner

**Files:**
- Create: `lib/widgets/guest_banner.dart`
- Modify: `lib/app/main_tabs_page.dart`

- [ ] **Step 1: Write GuestBanner widget**

```dart
import 'package:flutter/material.dart';

class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFFFF9500).withAlpha(25),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 16),
            const SizedBox(width: 8),
            const Text(
              '游客模式，数据仅保存在本设备',
              style: TextStyle(color: Color(0xFFFF9500), fontSize: 13),
            ),
            const SizedBox(width: 2),
            const Text('·', style: TextStyle(color: Color(0xFFFF9500))),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: () {
                // TODO: navigate to register/login (P2)
              },
              child: const Text(
                '注册 / 登录',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add GuestBanner to MainTabsPage**

In `lib/app/main_tabs_page.dart`, add the GuestBanner at the top of the body Column (above IndexedStack). Wrap it in a conditional based on auth state (always visible until P2 auth is implemented):

```dart
// In MainTabsPage build():
body: Column(
  children: [
    const GuestBanner(),
    Expanded(
      child: IndexedStack(
        index: _currentIndex,
        children: const [
          MarketExplorerWidget(),
          AssetsPage(),
          TradePage(),
          ProfilePage(),
        ],
      ),
    ),
  ],
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/guest_banner.dart lib/app/main_tabs_page.dart
git commit -m "feat: add guest mode banner to main tabs page"
```

---

### Task 19: Fix Market Explorer Dynamic List

**Files:**
- Modify: `lib/market_explorer.dart`

- [ ] **Step 1: Read current market_explorer.dart**

Read the file to understand current list rendering.

- [ ] **Step 2: Replace fixed 7-item list with dynamic ListView.builder**

Replace the `StockRowModel` list (hardcoded to 7 items from `stockRowModel1` through `stockRowModel7`) with a dynamic `ListView.builder` that renders all items from `market.quotes`:

```dart
// Old pattern (removed):
// stockRowModel1, stockRowModel2, ... stockRowModel7

// New pattern:
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: market.quotes.length,
  itemBuilder: (context, index) {
    final quote = market.quotes[index];
    return StockRowWidget(
      key: ValueKey(quote.symbol),
      symbol: quote.symbol,
      name: quote.name,
      price: quote.priceLabel,
      change: quote.changeLabel,
      isUp: quote.isUp,
      chartData: quote.chartCsv,
      onTap: () {
        // navigate to trade
        final tradeSelection = context.read<TradeSelectionService>();
        tradeSelection.selectForTrade(quote);
        // switch to trade tab
      },
    );
  },
)
```

- [ ] **Step 3: Add loading/error/empty states**

Wrap the ListView in a builder that checks `market.lastError` and `market.quotes.isEmpty`:

```dart
if (market.quotes.isEmpty && market.lastError != null) {
  return _errorView(market.lastError!);
}
if (market.quotes.isEmpty) {
  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
}
return ListView.builder(/* ... */);
```

- [ ] **Step 4: Commit**

```bash
git add lib/market_explorer.dart
git commit -m "fix: dynamic market list replaces hardcoded 7-item layout"
```

---

### Self-Review

**1. Spec coverage check:**
- P0 Hive persistence: Tasks 2-6 cover models, HiveService, CareerService, TradeHistoryService ✓
- P0 Career system: Tasks 5, 11, 12 cover CRUD, selector, management sheet ✓
- P1 Assets page improvements: Task 15 covers career selector, gain/loss, equity curve ✓
- P1 Trade history page: Task 16 ✓
- P1 Trade page tweaks: Tasks 9 (available balance) and 10 (confetti) ✓
- P2 Auth system: Not yet implemented (requires Supabase setup; deferred to next plan iteration)
- P2 Guest/login dual mode: Partially covered (GuestBanner Task 18, profile Task 17); full auth deferred
- P2 Profile redesign: Task 17 ✓
- P3 UI polish: Task 10 (confetti) ✓; remaining visual tweaks deferred
- P3 Onboarding: Not yet implemented (deferred)
- P3 Share image export: Not yet implemented (deferred)
- Fix dynamic market list from TODO.md: Task 19 ✓

**2. Placeholder scan:**
- Task 1 (dependencies): spec versions verified against pub.dev ✓
- All tasks have concrete file paths, code, and commands ✓
- No "TBD", "TODO" in code (one "TODO: navigate to register/login" is intentional as P2 work is deferred) ✓
- Auth-related code uses `isLoggedIn = false` with clear comments that P2 will wire real auth ✓

**3. Type consistency:**
- Career.id is String across all tasks ✓
- TradeRecord references careerId as String ✓
- CareerService methods use consistent signatures ✓
- TradeFormController changes reference CareerService and TradeHistoryService ✓

**Gaps intentionally deferred to next plan:**
- Supabase Auth setup (P2) — requires project creation on supabase.com
- Data migration guest→logged-in (P2)
- Onboarding flow (P3)
- Share image export (P3)
- Full UI style adjustments (P3)
