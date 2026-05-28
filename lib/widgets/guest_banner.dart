import 'package:flutter/material.dart';

class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFFFF9500).withAlpha(25),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '游客模式，数据仅保存在本设备',
                style: TextStyle(color: Color(0xFFFF9500), fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('注册/登录功能即将上线')),
                );
              },
              child: const Text(
                '注册 / 登录',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
