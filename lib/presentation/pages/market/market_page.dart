import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/presentation/pages/market/stock_detail_page.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/crypto_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
  int _selectedMarket = 0; // 0 = A股, 1 = 加密货币

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
    sorted.sort((a, b) => b.changePct.abs().compareTo(a.changePct.abs()));
    return sorted.take(count).toList();
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final aShare = context.watch<AShareService>();
    final crypto = context.watch<CryptoService>();
    final watchlist = context.watch<WatchlistService>();
    final portfolio = context.watch<PortfolioService>();
    final auth = context.watch<AuthService>();

    // Pick data source based on market selection
    final source = _selectedMarket == 0 ? aShare : crypto;
    final quotes = source.quotes;

    // Set initial tab based on auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (auth.isLoggedIn && watchlist.symbols.isNotEmpty && _tabController.index != 0) {
        _tabController.animateTo(0);
      } else if (!auth.isLoggedIn && _tabController.index != 2) {
        _tabController.animateTo(2);
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(context),
            // Market type selector (VIP only for crypto)
            if (auth.isVip) _buildMarketSelector(),
            _buildTabBar(),
            _buildSearchBar(),
            if (_selectedMarket == 0) _buildDelayNote(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWatchlistTab(watchlist, source, quotes),
                  _buildHoldingsTab(portfolio, source, quotes),
                  _buildHotTab(source, quotes),
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

  // ---- market selector -----------------------------------------------------

  Widget _buildMarketSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
      child: Row(
        children: [
          _marketChip('🇨🇳 A股', 0),
          const SizedBox(width: 8),
          _marketChip('₿ 加密货币', 1),
        ],
      ),
    );
  }

  Widget _marketChip(String label, int index) {
    final isSelected = _selectedMarket == index;
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.notoSansSc(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedMarket = index);
        if (index == 1) {
          context.read<CryptoService>().start();
        }
      },
      selectedColor: _amber,
      backgroundColor: _chipBg,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : _textSecondary,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // ---- tab bar -------------------------------------------------------------

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Text(
        AppText.dataDelayNote,
        style: TextStyle(color: _textMuted, fontSize: 11),
      ),
    );
  }

  // ---- Tab 1: Watchlist ----------------------------------------------------

  Widget _buildWatchlistTab(WatchlistService watchlist, MarketDataService source, List<StockQuote> quotes) {
    if (quotes.isEmpty) {
      return _loadingOrError(source);
    }

    if (watchlist.symbols.isEmpty) {
      return _emptyState('还没有关注股票', '去 🔥热门 发现感兴趣的股票，点击 ☆ 加入关注');
    }

    var filtered = quotes
        .where((q) => watchlist.isWatched(q.symbol))
        .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((q) =>
          q.symbol.toLowerCase().contains(_searchQuery) ||
          q.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (filtered.isEmpty) {
      return _emptyState('没有匹配结果', '试试其他搜索词');
    }

    return _buildStockListView(filtered, showStar: true);
  }

  // ---- Tab 2: Holdings -----------------------------------------------------

  Widget _buildHoldingsTab(PortfolioService portfolio, MarketDataService source, List<StockQuote> quotes) {
    if (portfolio.holdings.isEmpty) {
      return _emptyState('还没有持仓', '前往交易页开始你的第一笔模拟交易吧');
    }

    final priceMap = <String, double>{};
    for (final q in quotes) {
      priceMap[q.symbol] = q.price;
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: portfolio.holdings.length,
      itemBuilder: (context, i) {
        final h = portfolio.holdings[i];
        final livePrice = priceMap[h.symbol] ?? h.lastKnownPrice;
        final costPrice = h.avgCost;
        final pnl = (livePrice - costPrice) * h.amount;
        final costValue = costPrice * h.amount;
        final pnlPercent = costValue > 0 ? ((livePrice - costPrice) / costPrice * 100) : 0.0;
        final isUp = pnl >= 0;

        return GestureDetector(
          onTap: () {
            // Find matching StockQuote for detail navigation
            final quote = quotes.cast<StockQuote?>().firstWhere(
              (q) => q?.symbol == h.symbol,
              orElse: () => null,
            );
            if (quote != null) {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => StockDetailPage(quote: quote)));
            }
          },
          child: Container(
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
                      '${isUp ? "+" : ""}¥${pnl.toStringAsFixed(2)} (${isUp ? "+" : ""}${pnlPercent.toStringAsFixed(1)}%)',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isUp ? _green : _red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Tab 3: Hot ----------------------------------------------------------

  Widget _buildHotTab(MarketDataService source, List<StockQuote> quotes) {
    if (quotes.isEmpty) {
      return _loadingOrError(source);
    }

    var hot = _topHot(quotes);

    if (_searchQuery.isNotEmpty) {
      hot = hot.where((q) =>
          q.symbol.toLowerCase().contains(_searchQuery) ||
          q.name.toLowerCase().contains(_searchQuery)).toList();
    }

    if (hot.isEmpty) {
      return _emptyState('没有匹配结果', '试试其他搜索词');
    }

    return _buildStockListView(hot, showStar: true);
  }

  // ---- shared stock list ---------------------------------------------------

  Widget _buildStockListView(List<StockQuote> quotes, {bool showStar = false}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 60),
      itemCount: quotes.length,
      itemBuilder: (context, i) => _buildStockCard(quotes[i], showStar: showStar),
    );
  }

  Widget _buildStockCard(StockQuote row, {bool showStar = false}) {
    final isUp = row.isUp;
    final changeColor = isUp ? _green : _red;
    final changeBg = isUp ? _greenBg : _redBg;
    final sector = _sectorFor(row);
    final watchlist = context.watch<WatchlistService>();
    final isWatched = watchlist.isWatched(row.symbol);

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

  Widget _loadingOrError(MarketDataService source) {
    if (source.lastError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: _textMuted),
            const SizedBox(height: 12),
            Text(source.lastError!, textAlign: TextAlign.center,
              style: GoogleFonts.notoSansSc(fontSize: 14, color: _textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => source.refresh(),
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
