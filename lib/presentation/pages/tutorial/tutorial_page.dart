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
  TutorialChapter(index: 3, title: '限价单 vs 市价单', emoji: '📝', content: '限价单：指定你愿意买入/卖出的价格。只有市场价格达到你的要求才会成交。适合控制成本。\n\n市价单：以当前市场价格立即成交。速度快但价格可能不理想。\n\n新手建议先用限价单练习。'),
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
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                    child: const Text('上一页', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  const SizedBox(width: 80),
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
                    child: const Text('下一页'),
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
                    child: const Text('完成'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
