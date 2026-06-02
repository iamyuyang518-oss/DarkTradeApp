import 'package:dark_trade_app/app/app.dart';
import 'package:dark_trade_app/data/local/hive_service.dart';
import 'package:dark_trade_app/data/repositories/career_repository.dart';
import 'package:dark_trade_app/data/repositories/trade_history_repository.dart';
import 'package:dark_trade_app/data/repositories/watchlist_repository.dart';
import 'package:dark_trade_app/data/remote/supabase_client.dart';
import 'package:dark_trade_app/domain/services/a_share_service.dart';
import 'package:dark_trade_app/domain/services/achievement_service.dart';
import 'package:dark_trade_app/domain/services/auth_service.dart';
import 'package:dark_trade_app/domain/services/battle_service.dart';
import 'package:dark_trade_app/domain/services/leaderboard_service.dart';
import 'package:dark_trade_app/domain/services/career_service.dart';
import 'package:dark_trade_app/domain/services/crypto_service.dart';
import 'package:dark_trade_app/domain/services/market_sentiment_service.dart';
import 'package:dark_trade_app/domain/services/portfolio_service.dart';
import 'package:dark_trade_app/domain/services/trade_history_service.dart';
import 'package:dark_trade_app/domain/services/trade_selection_service.dart';
import 'package:dark_trade_app/domain/services/watchlist_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await SupabaseClientManager.init();

  // Create repositories
  final careerRepo = HiveCareerRepo();
  final tradeHistoryRepo = HiveTradeHistoryRepo();

  // Create services with repository dependencies
  final careerService = CareerService(
    localRepo: careerRepo,
    tradeHistoryRepo: tradeHistoryRepo,
  )..load();
  final tradeHistory = TradeHistoryService(localRepo: tradeHistoryRepo);

  final aShare = AShareService()..start();
  final crypto = CryptoService(); // lazy start — begins when user switches to crypto tab
  final portfolio = PortfolioService()..seedDemo();
  final tradeSelection = TradeSelectionService();

  final watchlistRepo = HiveWatchlistRepo();
  final watchlistService = WatchlistService(localRepo: watchlistRepo)..load();

  final achievementService = AchievementService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: aShare),
        ChangeNotifierProvider.value(value: crypto),
        ChangeNotifierProvider.value(value: portfolio),
        ChangeNotifierProvider.value(value: tradeSelection),
        ChangeNotifierProvider.value(value: watchlistService),
        ChangeNotifierProvider.value(value: achievementService),
        ChangeNotifierProvider(create: (_) => LeaderboardService()),
        ChangeNotifierProvider.value(value: careerService),
        ChangeNotifierProvider.value(value: tradeHistory),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BattleService()),
        ChangeNotifierProvider(create: (_) => MarketSentimentService()),
      ],
      child: const DarkTradeApp(),
    ),
  );
}
