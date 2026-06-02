// lib/core/constants.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // 背景与表面
  static const Color background = Color(0xFFFFF9F0);
  static const Color surface = Color(0xFFFFFEFB);
  static const Color border = Color(0xFFECDCC0);

  // 强调色 — 金色系
  static const Color gold = Color(0xFFD4A853);
  static const Color goldDark = Color(0xFFC49B38);
  static const Color goldBg = Color(0xFFFDF6E8);
  static const Color goldBorder = Color(0xFFF5E6C8);

  // 文字
  static const Color textPrimary = Color(0xFF4A3828);
  static const Color textSecondary = Color(0xFFB8977A);
  static const Color textMuted = Color(0xFFC8B898);

  // 涨跌
  static const Color up = Color(0xFF5CB860);
  static const Color upBg = Color(0xFFE8F5E9);
  static const Color down = Color(0xFFE88580);
  static const Color downBg = Color(0xFFFFF0F0);

  // 非选中（保留兼容旧引用）
  static const Color unselectedBg = Color(0xFFF5EDE0);
  static const Color unselectedText = Color(0xFFB8976A);

  // 导航（保留兼容旧引用，Phase 2 改用 Sidebar）
  static const Color navBg = Color(0xFFFFF9F0);
  static const Color navSelected = Color(0xFFD4A853);
  static const Color navUnselected = Color(0xFFB8977A);

  // 情绪色板
  static const Color emotionZen = Color(0xFFB8D4C8);
  static const Color emotionZenBg = Color(0xFFEDF5F0);
  static const Color emotionPopcorn = Color(0xFFF5E6C8);
  static const Color emotionPopcornBg = Color(0xFFFDF6E8);
  static const Color emotionFire = Color(0xFFF0C8C0);
  static const Color emotionFireBg = Color(0xFFFDF2F0);
}

abstract class AppDimens {
  AppDimens._();

  // 圆角统一
  static const double radiusXs = 4.0;   // 小标签
  static const double radiusSm = 8.0;   // 芯片/标签
  static const double radiusMd = 12.0;  // 按钮/输入框/侧边栏导航
  static const double radiusLg = 16.0;  // 卡片
  static const double radiusXl = 18.0;  // 弹窗/底部面板

  // 间距
  static const double paddingPage = 20.0;
  static const double paddingCard = 16.0;
  static const double gapXs = 4.0;
  static const double gapSm = 8.0;
  static const double gapMd = 12.0;
  static const double gapLg = 16.0;

  // 侧边栏
  static const double sidebarWidth = 220.0;
}

abstract class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x0AA08C6E),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const hover = [
    BoxShadow(
      color: Color(0x1FD4A853),
      blurRadius: 24,
      offset: Offset(0, 6),
    ),
  ];

  static const modal = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  static const goldButton = [
    BoxShadow(
      color: Color(0x4DD4A853),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}

abstract class AppText {
  AppText._();
  static const String appName = 'DarkTrade';
  static const String tagline = 'A 股模拟交易练习平台';
  static const String guestBanner = '游客模式，数据仅保存在本设备';
  static const String registerLogin = '注册 / 登录';
  static const String disclaimerFooter = '模拟交易 · 仅供学习 · 不构成投资建议';
  static const String dataDelayNote = '行情数据可能存在五分钟延迟';
  static const String riskTitle = '风险提示';
  static const String riskBody =
      '本平台为模拟交易工具，所有资金均为虚拟资金。\n'
      '行情数据来源于公开接口，可能存在五分钟延迟。\n'
      '模拟交易体验不代表真实市场表现。\n'
      '本平台不构成任何投资建议。\n'
      '股市有风险，投资需谨慎。';
  static const String agreeTerms = '我已了解并同意用户协议和隐私政策';

  // New warm copy
  static const String emptyHoldings = '还没有持仓哦，去探索市场吧~';
  static const String emptyWatchlist = '去热门发现感兴趣的股票，点 ☆ 加入关注';
  static const String emptyWatchlistTitle = '还没有关注股票';
  static const String emptyHoldingsTitle = '暂无持仓';
  static const String noMatchResult = '没有匹配结果';
  static const String tryOtherSearch = '试试其他搜索词';
  static const String loadingData = '数据正在路上... 🚀';
  static const String networkError = '网络开了小差，点此重试 🔄';
  static const String tradeSuccess = '成交！离大佬又近了一步 👍';
  static const String balanceInsufficient = '差一点就够啦，调整一下数量？';
  static const String newbieTip = '建议先用 25% 仓位小试牛刀~';
  static String highFrequency(String count) => '本周已交易 $count 次，注意休息！喝杯茶 🍵';
}
