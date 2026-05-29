import 'package:dark_trade_app/app/app.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestCareerRepo implements CareerRepository {
  @override
  Future<List<Career>> loadCareers() async => [];
  @override
  Future<void> saveCareer(Career career) async {}
  @override
  Future<void> deleteCareer(String id) async {}
  @override
  Future<void> saveAllCareers(List<Career> careers) async {}
  @override
  Future<List<Career>> migrateFromLocal() async => [];
}

class _TestTradeHistoryRepo implements TradeHistoryRepository {
  @override
  Future<List<TradeRecord>> loadRecords(String careerId) async => [];
  @override
  Future<void> saveRecord(TradeRecord record) async {}
  @override
  Future<void> deleteRecord(String id) async {}
  @override
  Future<void> saveAllRecords(List<TradeRecord> records) async {}
  @override
  Future<List<TradeRecord>> migrateFromLocal(String careerId) async => [];
}

void main() {
  testWidgets('DarkTradeApp builds with bottom navigation',
      (WidgetTester tester) async {
    final aShare = AShareService();
    final portfolio = PortfolioService()..seedDemo();
    final tradeSelection = TradeSelectionService();
    final careerRepo = _TestCareerRepo();
    final tradeHistoryRepo = _TestTradeHistoryRepo();
    final careerService = CareerService(
      localRepo: careerRepo,
      tradeHistoryRepo: tradeHistoryRepo,
    )..load();
    final tradeHistory = TradeHistoryService(localRepo: tradeHistoryRepo);
    final auth = AuthService();
    // Wire services so MainTabsPage can wire them again without issue
    auth.wireServices(careerService, tradeHistory);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: aShare),
          ChangeNotifierProvider.value(value: portfolio),
          ChangeNotifierProvider.value(value: tradeSelection),
          ChangeNotifierProvider.value(value: careerService),
          ChangeNotifierProvider.value(value: tradeHistory),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const DarkTradeApp(),
      ),
    );
    await tester.pump();

    expect(find.text('行情'), findsOneWidget);
    expect(find.text('资产'), findsOneWidget);

    aShare.dispose();
    portfolio.dispose();
    careerService.dispose();
    tradeHistory.dispose();
    tradeSelection.dispose();
    auth.dispose();
  });
}
