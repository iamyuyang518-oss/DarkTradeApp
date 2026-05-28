import 'package:dark_trade_app/components/category_chip/category_chip_widget.dart';
import 'package:dark_trade_app/components/stock_row/stock_row_widget.dart';
import 'package:dark_trade_app/flutter_flow/flutter_flow_theme.dart';
import 'package:dark_trade_app/flutter_flow/flutter_flow_util.dart';
import 'package:dark_trade_app/pages/stock_detail_page.dart';
import 'package:dark_trade_app/services/a_share_service.dart';
import 'package:dark_trade_app/services/live_market_service.dart';
import 'package:dark_trade_app/services/market_data_service.dart';
import 'package:dark_trade_app/services/trade_selection_service.dart';
import 'package:dark_trade_app/services/us_stock_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Page model
// ---------------------------------------------------------------------------

class MarketExplorerModel extends FlutterFlowModel<MarketExplorerWidget> {
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = '全部';
  final Set<String> expandedIds = {};

  void toggleExpanded(String id) {
    if (expandedIds.contains(id)) {
      expandedIds.remove(id);
    } else {
      expandedIds.add(id);
    }
    notifyListeners();
  }

  void _onSearchChanged() => notifyListeners();

  @override
  void initState(BuildContext context) {
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}

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
  late MarketExplorerModel _model;
  late TabController _tabController;

  static const _tabs = ['加密货币', '美股', 'A股'];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MarketExplorerModel());
    _model.initState(context);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _model.notifyListeners();
      }
    });
    registerFfmPageSetState((fn) {
      if (mounted) setState(fn);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    unregisterFfmPageSetState();
    _model.dispose();
    super.dispose();
  }

  // ---- helpers -------------------------------------------------------------

  String _formatVolume(double usd) {
    if (usd >= 1e12) return '\$${(usd / 1e12).toStringAsFixed(1)}T';
    if (usd >= 1e9) return '\$${(usd / 1e9).toStringAsFixed(1)}B';
    if (usd >= 1e6) return '\$${(usd / 1e6).toStringAsFixed(1)}M';
    return '\$${usd.toStringAsFixed(0)}';
  }

  MarketDataService _serviceForTab(int index) {
    return switch (index) {
      1 => context.read<UsStockService>(),
      2 => context.read<AShareService>(),
      _ => context.read<LiveMarketService>(),
    };
  }

  List<String> _categoriesForTab(int index) {
    return switch (index) {
      1 => ['全部', '科技', '金融', '医疗', '能源', '消费', '工业'],
      2 => ['全部', '金融', '科技', '医药', '消费', '能源', '综合'],
      _ => ['全部', 'Layer1', 'DeFi', 'Meme', '平台币', '其他'],
    };
  }

  String? _categoryFor(StockQuote q) {
    switch (q.marketType) {
      case MarketType.crypto:
        return _cryptoCat(q.symbol.toUpperCase());
      case MarketType.usStock:
        return UsStockService.sectorMap[q.symbol];
      case MarketType.aShare:
        return AShareService.sectorForCode(q.symbol);
    }
  }

  static String? _cryptoCat(String symbol) {
    const layer1 = {
      'BTC', 'ETH', 'SOL', 'AVAX', 'DOT', 'ATOM', 'NEAR', 'ADA',
      'XRP', 'TRX', 'ETC', 'LTC', 'FIL', 'XLM',
    };
    const defi = {'UNI', 'LINK'};
    const meme = {'DOGE', 'SHIB'};
    const platform = {'BNB', 'MATIC'};
    if (layer1.contains(symbol)) return 'Layer1';
    if (defi.contains(symbol)) return 'DeFi';
    if (meme.contains(symbol)) return 'Meme';
    if (platform.contains(symbol)) return '平台币';
    return '其他';
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<LiveMarketService>();
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: const ValueKey('MarketExplorer'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Column(
              children: [
                _buildHeader(context, crypto),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                  ),
                ),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMarketTab(context, 0),
                      _buildMarketTab(context, 1),
                      _buildMarketTab(context, 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- header --------------------------------------------------------------

  Widget _buildHeader(BuildContext context, LiveMarketService crypto) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 48, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Market Explorer',
                style: theme.headlineMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryText,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications_none_rounded,
                    color: theme.secondaryText, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        crypto.lastNetworkNote ?? '暂无通知',
                        style: const TextStyle(color: Colors.black),
                      ),
                      backgroundColor: theme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _model.searchController,
              onChanged: (_) => _model._onSearchChanged(),
              style: theme.bodyMedium.override(
                color: theme.primaryText,
              ),
              decoration: InputDecoration(
                hintText: '搜索币种、代码或板块...',
                hintStyle: theme.labelSmall.override(color: theme.secondaryText),
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.secondaryText, size: 20),
                filled: true,
                fillColor: theme.secondaryBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.alternate),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.alternate),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- tab bar -------------------------------------------------------------

  Widget _buildTabBar(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: theme.primaryBackground,
      child: TabBar(
        controller: _tabController,
        indicatorColor: theme.primary,
        indicatorWeight: 2,
        labelColor: theme.primary,
        unselectedLabelColor: theme.secondaryText,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ---- tab content ---------------------------------------------------------

  Widget _buildMarketTab(BuildContext context, int tabIndex) {
    final service = _serviceForTab(tabIndex);

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryChips(context, tabIndex),
              _buildMarketCards(context, service),
              _buildListHeader(context),
              _buildStockList(context, service),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ---- category chips ------------------------------------------------------

  Widget _buildCategoryChips(BuildContext context, int tabIndex) {
    final categories = _categoriesForTab(tabIndex);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 0, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((cat) {
            final selected = _model.selectedCategory == cat;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: CategoryChipWidget(
                label: cat,
                selected: selected,
                onTap: () {
                  _model.selectedCategory = cat;
                  _model.notifyListeners();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---- market cards --------------------------------------------------------

  Widget _buildMarketCards(BuildContext context, MarketDataService service) {
    final theme = FlutterFlowTheme.of(context);
    final quotes = service.quotes;
    final avg = quotes.isEmpty
        ? 0.0
        : quotes.map((e) => e.changePct).reduce((a, b) => a + b) / quotes.length;
    final bullish = avg >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(context, children: [
              Text('Market Mood',
                  style: theme.labelSmall.override(
                      color: theme.secondaryText, letterSpacing: 0.0)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                    bullish
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: bullish
                        ? theme.success
                        : Theme.of(context).colorScheme.error,
                    size: 16),
                const SizedBox(width: 4),
                Text(bullish ? 'Bullish' : 'Bearish',
                    style: theme.bodyMedium.override(
                        fontWeight: FontWeight.bold,
                        color: bullish
                            ? theme.success
                            : Theme.of(context).colorScheme.error,
                        letterSpacing: 0.0)),
              ]),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCard(context, children: [
              Text('Vol. (24h)',
                  style: theme.labelSmall.override(
                      color: theme.secondaryText, letterSpacing: 0.0)),
              const SizedBox(height: 4),
              Text(_formatVolume(service.totalVolumeUsd),
                  style: theme.bodyMedium.override(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryText,
                      letterSpacing: 0.0)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.alternate, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ---- list header ---------------------------------------------------------

  Widget _buildListHeader(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.secondaryBackground),
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('行情列表',
              style: theme.labelLarge.override(
                  fontWeight: FontWeight.bold,
                  color: theme.secondaryText,
                  letterSpacing: 0.0)),
        ],
      ),
    );
  }

  // ---- stock list ----------------------------------------------------------

  Widget _buildStockList(BuildContext context, MarketDataService service) {
    // ---- empty / error states -----------------------------------------------
    if (service.quotes.isEmpty) {
      if (service.lastError != null) {
        // Error state -- no cached data either
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 40,
                    color: FlutterFlowTheme.of(context).secondaryText),
                const SizedBox(height: 12),
                Text(
                  service.lastError!,
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => service.refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      }
      // Loading state -- no error yet, waiting for first fetch
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final q = _model.searchController.text.trim().toLowerCase();
    var filtered = q.isEmpty
        ? service.quotes
        : service.quotes
            .where((r) =>
                r.symbol.toLowerCase().contains(q) ||
                r.name.toLowerCase().contains(q))
            .toList();

    // Category filter
    if (_model.selectedCategory != '全部') {
      final cat = _model.selectedCategory;
      filtered = filtered.where((r) => _categoryFor(r) == cat).toList();
    }

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('没有匹配的结果，试试其他搜索词。'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final row = filtered[i];
        return StockRowWidget(
          key: ValueKey(row.id),
          change: row.changeLabel,
          chartData: row.chartCsv,
          name: row.name,
          price: row.priceLabel,
          symbol: row.symbol,
          isUp: row.isUp,
          expanded: _model.expandedIds.contains(row.id),
          // 点击行直接进入详情页
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockDetailPage(quote: row),
            ),
          ),
          onTradeTap: () =>
              context.read<TradeSelectionService>().selectForTrade(row),
          onDetailTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockDetailPage(quote: row),
            ),
          ),
          // 箭头按钮：展开/折叠 sparkline
          onArrowTap: () => _model.toggleExpanded(row.id),
        );
      },

    );
  }
}
