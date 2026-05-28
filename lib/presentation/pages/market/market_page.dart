import 'package:dark_trade_app/presentation/pages/market/stock_detail_page.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/market_data_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Page model
// ---------------------------------------------------------------------------

class MarketExplorerModel extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  String _selectedCategory = '全部';
  String get selectedCategory => _selectedCategory;
  final Set<String> expandedIds = {};

  void selectCategory(String cat) {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    notifyListeners();
  }

  void toggleExpanded(String id) {
    if (expandedIds.contains(id)) {
      expandedIds.remove(id);
    } else {
      expandedIds.add(id);
    }
    notifyListeners();
  }

  void _onSearchChanged() => notifyListeners();

  void init() {
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

class _MarketExplorerWidgetState extends State<MarketExplorerWidget> {
  late final MarketExplorerModel _model;

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

  static const _categories = ['全部', '金融', '科技', '医药', '消费', '能源', '综合'];

  @override
  void initState() {
    super.initState();
    _model = MarketExplorerModel();
    _model.init();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ---- helpers -------------------------------------------------------------

  String? _categoryFor(StockQuote q) {
    if (q.marketType == MarketType.aShare) {
      return AShareService.sectorForCode(q.symbol);
    }
    return null;
  }

  // ---- mood computation ----------------------------------------------------

  _MoodData _computeMood(List<StockQuote> quotes) {
    if (quotes.isEmpty) return _MoodData(score: 50, upCount: 0, downCount: 0);
    final upCount = quotes.where((q) => q.isUp).length;
    final downCount = quotes.length - upCount;
    final score = ((upCount / quotes.length) * 100).round();
    return _MoodData(score: score, upCount: upCount, downCount: downCount);
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AShareService>();
    final mood = _computeMood(service.quotes);

    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: const ValueKey('MarketExplorer'),
            backgroundColor: _bg,
            body: Column(
              children: [
                _buildHeader(context),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(color: _border),
                ),
                SizedBox(
                  height: 42,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Row(
                      children: [
                        Text('A 股', style: GoogleFonts.notoSansSc(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _amber,
                        )),
                        const SizedBox(width: 8),
                        Container(
                          width: 1, height: 16,
                          color: _border,
                        ),
                        const SizedBox(width: 8),
                        Text('实时行情', style: GoogleFonts.notoSansSc(
                          fontSize: 12, color: _textSecondary,
                        )),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCategoryChips(context),
                        _buildMoodCard(mood),
                        _buildStockList(context, service),
                        if (service.quotes.isNotEmpty) _buildBeginnerTip(),
                      ],
                    ),
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

  Widget _buildHeader(BuildContext context) {
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
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
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
                      decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle,
                      ),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _model.searchController,
              onChanged: (_) => _model._onSearchChanged(),
              style: GoogleFonts.notoSansSc(fontSize: 14, color: _textPrimary),
              decoration: InputDecoration(
                hintText: '搜索股票代码或名称...',
                hintStyle: GoogleFonts.notoSansSc(fontSize: 14, color: _textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 20),
                filled: true,
                fillColor: _cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _amber, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- mood card -----------------------------------------------------------

  Widget _buildMoodCard(_MoodData mood) {
    final moodLabel = mood.score >= 60 ? '偏乐观' : mood.score <= 40 ? '偏恐慌' : '观望中';
    final moodEmoji = mood.score >= 70 ? '☀️' : mood.score >= 50 ? '🌤️' : mood.score >= 30 ? '🌧️' : '⛈️';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8ED), Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E0C0)),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('市场情绪', style: GoogleFonts.notoSansSc(
                    fontSize: 12, color: Color(0xFFB8976A),
                    fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${mood.score}', style: GoogleFonts.playfairDisplay(
                        fontSize: 36, fontWeight: FontWeight.bold, color: _textPrimary,
                      )),
                      const SizedBox(width: 6),
                      Text('/100 · $moodLabel', style: GoogleFonts.notoSansSc(
                        fontSize: 14, color: Color(0xFFB8976A),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Container(color: const Color(0xFFE8C9A0))),
                          Expanded(flex: 3, child: Container(color: const Color(0xFFD4B896))),
                          Expanded(flex: 4, child: Container(color: const Color(0xFFC4A060))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['恐慌', '观望', '贪婪'].map((l) => Text(l, style: GoogleFonts.notoSansSc(
                      fontSize: 10, color: Color(0xFFC4B090),
                    ))).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(moodEmoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 4),
                Text('${mood.upCount}涨 ${mood.downCount}跌', style: GoogleFonts.notoSansSc(
                  fontSize: 12, color: _amber, fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- category chips ------------------------------------------------------

  Widget _buildCategoryChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((cat) {
            final selected = _model.selectedCategory == cat;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: GestureDetector(
                onTap: () => _model.selectCategory(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _amber : _chipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? null : Border.all(color: _border),
                    boxShadow: selected ? [
                      BoxShadow(color: _amber.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2)),
                    ] : null,
                  ),
                  child: Text(cat, style: GoogleFonts.notoSansSc(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : _textSecondary,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---- stock list ----------------------------------------------------------

  Widget _buildStockList(BuildContext context, MarketDataService service) {
    // Empty / error / loading states
    if (service.quotes.isEmpty) {
      if (service.lastError != null) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: _textMuted),
              const SizedBox(height: 12),
              Text(service.lastError!, textAlign: TextAlign.center,
                style: GoogleFonts.notoSansSc(fontSize: 14, color: _textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => service.refresh(),
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
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: _amber)),
      );
    }

    final q = _model.searchController.text.trim().toLowerCase();
    var filtered = q.isEmpty
        ? service.quotes
        : service.quotes.where((r) =>
            r.symbol.toLowerCase().contains(q) ||
            r.name.toLowerCase().contains(q)).toList();

    if (_model.selectedCategory != '全部') {
      final cat = _model.selectedCategory;
      filtered = filtered.where((r) => _categoryFor(r) == cat).toList();
    }

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('没有匹配的结果，试试其他搜索词。',
          style: GoogleFonts.notoSansSc(color: _textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // List header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('行情列表', style: GoogleFonts.notoSansSc(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _textSecondary,
                )),
                Text('${filtered.length} 只', style: GoogleFonts.notoSansSc(
                  fontSize: 12, color: _textMuted,
                )),
              ],
            ),
          ),

          // Stock cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildStockCard(filtered[i]),
          ),
        ],
      ),
    );
  }

  // ---- stock card ----------------------------------------------------------

  Widget _buildStockCard(StockQuote row) {
    final isUp = row.isUp;
    final changeColor = isUp ? _green : _red;
    final changeBg = isUp ? _greenBg : _redBg;
    final sector = _categoryFor(row);

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => StockDetailPage(quote: row))),
      child: Container(
        key: ValueKey(row.id),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: isUp ? _green.withAlpha(12) : Colors.black.withAlpha(6),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Left side: symbol + name + sector tag + sparkline
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _chipBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(sector, style: GoogleFonts.notoSansSc(
                                  fontSize: 10, color: _amber, fontWeight: FontWeight.w600,
                                )),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(row.name, style: GoogleFonts.notoSansSc(
                          fontSize: 13, color: _textSecondary,
                        )),
                        const SizedBox(height: 8),
                        _buildMiniSparkline(row.chartCsv, isUp),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side: price + change + hi/lo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(row.priceLabel, style: GoogleFonts.notoSansSc(
                        fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary,
                      )),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: changeBg, borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${isUp ? "▲" : "▼"} ${row.changeLabel}',
                          style: GoogleFonts.notoSansSc(
                            fontSize: 13, fontWeight: FontWeight.w700, color: changeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action bar
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.read<TradeSelectionService>().selectForTrade(row),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('去交易', style: GoogleFonts.notoSansSc(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _amber,
                        )),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: _amber),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _model.toggleExpanded(row.id),
                    child: Icon(
                      _model.expandedIds.contains(row.id)
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20, color: _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Expandable area (reserved for future chart)
            if (_model.expandedIds.contains(row.id))
              Container(
                width: double.infinity,
                height: 2,
                color: _border,
              ),
          ],
        ),
      ),
    );
  }

  // ---- mini sparkline ------------------------------------------------------

  Widget _buildMiniSparkline(String chartCsv, bool isUp) {
    final values = chartCsv.split(',').map((e) => double.tryParse(e) ?? 0).toList();
    if (values.length < 2) return const SizedBox(height: 28);

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs();
    final normalized = range > 0
        ? values.map((v) => ((v - minVal) / range) * 0.8 + 0.1).toList()
        : values.map((_) => 0.5).toList();

    return SizedBox(
      height: 28,
      width: 90,
      child: CustomPaint(
        painter: _SparklineBarPainter(
          values: normalized,
          color: isUp ? _green : _red,
        ),
      ),
    );
  }

  // ---- beginner tip --------------------------------------------------------

  Widget _buildBeginnerTip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBF0), Color(0xFFFFF8ED)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8D4A8), strokeAlign: BorderSide.strokeAlignInside),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('新手提示', style: GoogleFonts.notoSansSc(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC49B38),
                  )),
                  const SizedBox(height: 2),
                  Text('点击任意股票卡片，查看详细 K 线走势和交易入口',
                    style: GoogleFonts.notoSansSc(fontSize: 12, color: Color(0xFFB8A080)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- mood data class -------------------------------------------------------

class _MoodData {
  final int score;
  final int upCount;
  final int downCount;
  const _MoodData({required this.score, required this.upCount, required this.downCount});
}

// ---- sparkline bar painter -------------------------------------------------

class _SparklineBarPainter extends CustomPainter {
  _SparklineBarPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = stepX * i;
      final y = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklineBarPainter old) =>
      old.values != values || old.color != color;
}
