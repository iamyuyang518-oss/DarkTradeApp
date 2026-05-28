// lib/core/constants.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // 背景与表面
  static const Color background = Color(0xFFFFFBF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8DCC8);

  // 强调色
  static const Color gold = Color(0xFFD4A853);

  // 文字
  static const Color textPrimary = Color(0xFF3D3025);
  static const Color textSecondary = Color(0xFFA09078);

  // 涨跌
  static const Color up = Color(0xFF43A047);
  static const Color upBg = Color(0xFFE8F5E9);
  static const Color down = Color(0xFFE57373);
  static const Color downBg = Color(0xFFFFF0F0);

  // 其他
  static const Color unselectedBg = Color(0xFFF5EDE0);
  static const Color unselectedText = Color(0xFFB8976A);
  static const Color navBg = Color(0xFFFFFBF5);
  static const Color navSelected = Color(0xFFD4A853);
  static const Color navUnselected = Color(0xFFA09078);
}

abstract class AppDimens {
  AppDimens._();
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double paddingPage = 16.0;
  static const double paddingCard = 14.0;
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
}
