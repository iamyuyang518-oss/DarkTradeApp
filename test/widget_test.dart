import 'package:dark_trade_app/main.dart';
import 'package:dark_trade_app/services/live_market_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('DarkTradeApp builds with bottom navigation', (WidgetTester tester) async {
    final market = LiveMarketService();

    await tester.pumpWidget(
      ChangeNotifierProvider<LiveMarketService>.value(
        value: market,
        child: const DarkTradeApp(),
      ),
    );
    await tester.pump();

    expect(find.text('行情'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);

    market.dispose();
  });
}
