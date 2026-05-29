import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';
import 'package:dark_trade_app/data/local/models/career.dart';
import 'package:dark_trade_app/data/local/models/trade_record.dart';
import 'package:dark_trade_app/presentation/pages/profile/auth_sheet.dart';

class _FakeCareerRepo implements CareerRepository {
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

class _FakeTradeHistoryRepo implements TradeHistoryRepository {
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
  group('AuthSheet UI', () {
    late AuthService auth;
    late CareerService careerService;
    late TradeHistoryService tradeHistory;

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider.value(value: careerService),
              ChangeNotifierProvider.value(value: tradeHistory),
            ],
            child: const AuthSheet(),
          ),
        ),
      );
    }

    setUp(() {
      auth = AuthService();
      careerService = CareerService(
        localRepo: _FakeCareerRepo(),
        tradeHistoryRepo: _FakeTradeHistoryRepo(),
      );
      tradeHistory = TradeHistoryService(localRepo: _FakeTradeHistoryRepo());
    });

    testWidgets('shows login form by default', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('登录'), findsWidgets);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('忘记密码？'), findsOneWidget);
      expect(find.text('确认密码'), findsNothing);
      expect(find.text('安全问题（找回密码用）'), findsNothing);
    });

    testWidgets('can toggle to register mode', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('没有账号？去注册'));
      await tester.pump();

      expect(find.text('注册'), findsWidgets);
      expect(find.text('确认密码'), findsOneWidget);
      expect(find.text('安全问题（找回密码用）'), findsOneWidget);
      expect(find.text('答案'), findsOneWidget);
      expect(find.text('忘记密码？'), findsNothing);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Tap the login button (last '登录' text is the button)
      await tester.tap(find.text('登录').last);
      await tester.pump();

      expect(find.text('用户名至少 2 位'), findsOneWidget);
      expect(find.text('密码至少 6 位'), findsOneWidget);
    });
  });
}
