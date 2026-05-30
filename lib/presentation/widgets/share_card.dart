import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dark_trade_app/core/constants.dart';
import 'package:dark_trade_app/data/local/models/career.dart';

class ShareCard extends StatelessWidget {
  final Career career;
  final String username;

  const ShareCard({super.key, required this.career, required this.username});

  @override
  Widget build(BuildContext context) {
    final totalReturn = career.totalReturnRate;
    final isUp = totalReturn >= 0;
    final totalEquity = career.initialBalance + (career.initialBalance * totalReturn / 100);

    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFFFF3E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D4A8), width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('D', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Text('DarkTrade', style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
              )),
            ],
          ),
          // Main stats
          Column(
            children: [
              Text(username, style: GoogleFonts.notoSansSc(
                fontSize: 16, color: AppColors.textSecondary,
              )),
              const SizedBox(height: 8),
              Text(career.name, style: GoogleFonts.notoSansSc(
                fontSize: 14, color: AppColors.gold, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 20),
              Text('¥${totalEquity.toStringAsFixed(2)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isUp ? AppColors.upBg : AppColors.downBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isUp ? "+" : ""}${totalReturn.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: isUp ? AppColors.up : AppColors.down,
                  ),
                ),
              ),
            ],
          ),
          // Footer
          Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('QR', style: TextStyle(color: AppColors.textSecondary))),
              ),
              const SizedBox(height: 8),
              Text('扫描二维码体验 DarkTrade',
                style: GoogleFonts.notoSansSc(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text(AppText.disclaimerFooter,
                style: TextStyle(fontSize: 9, color: AppColors.unselectedText)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper to capture and share
Future<void> sharePerformanceCard(BuildContext context, Career career, String username) async {
  final key = GlobalKey();
  final widget = RepaintBoundary(
    key: key,
    child: ShareCard(career: career, username: username),
  );

  // Render offscreen
  final overlay = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -1000,
      child: Material(child: widget),
    ),
  );
  Overlay.of(context).insert(overlay);

  await Future.delayed(const Duration(milliseconds: 500));

  try {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        await Share.shareXFiles([XFile.fromData(bytes, name: 'darktrade_share.png')],
          text: '我在 DarkTrade 的模拟交易成绩，来一起练习吧！',
        );
      }
    }
  } finally {
    overlay.remove();
  }
}
