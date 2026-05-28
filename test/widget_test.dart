import 'package:dark_trade_app/app/app.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('DarkTradeApp builds with bottom navigation', (WidgetTester tester) async {
    final aShare = AShareService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AShareService>.value(
        value: aShare,
        child: const DarkTradeApp(),
      ),
    );
    await tester.pump();

    expect(find.text('行情'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);

    aShare.dispose();
  });
}
