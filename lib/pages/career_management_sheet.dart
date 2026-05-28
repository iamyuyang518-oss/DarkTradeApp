import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/career_service.dart';
import '../models/career.dart';

class CareerManagementSheet extends StatefulWidget {
  const CareerManagementSheet({super.key});

  @override
  State<CareerManagementSheet> createState() => _CareerManagementSheetState();
}

class _CareerManagementSheetState extends State<CareerManagementSheet> {
  @override
  Widget build(BuildContext context) {
    final careerService = context.watch<CareerService>();
    final careers = careerService.careers;
    final active = careerService.activeCareer;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              child: Divider(color: Colors.white24, thickness: 3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '生涯管理',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...careers.map((c) => _careerTile(c, c.id == active?.id, careerService)),
          const SizedBox(height: 12),
          _createButton(careerService),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _careerTile(Career career, bool isActive, CareerService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFD700).withAlpha(25) : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: const Color(0xFFFFD700)) : null,
      ),
      child: ListTile(
        title: Text(career.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '初始资金 \$${career.initialBalance.toStringAsFixed(0)}  收益率 ${career.totalReturnRate.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              TextButton(
                onPressed: () {
                  service.switchCareer(career.id);
                  Navigator.pop(context);
                },
                child: const Text('切换', style: TextStyle(color: Color(0xFFFFD700))),
              ),
            if (service.careers.length > 1)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () {
                  service.deleteCareer(career.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _createButton(CareerService service) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCreateDialog(service),
        icon: const Icon(Icons.add, color: Color(0xFFFFD700)),
        label: const Text('新建生涯', style: TextStyle(color: Color(0xFFFFD700))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFD700)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showCreateDialog(CareerService service) {
    final careerCount = service.careers.length;
    final nameCtrl = TextEditingController(text: '生涯 #${careerCount + 1}');
    final balanceCtrl = TextEditingController(text: '100000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('新建生涯', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '生涯名称',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '初始资金 (USDT)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final balance = double.tryParse(balanceCtrl.text.trim()) ?? 100000;
              if (name.isNotEmpty) {
                service.createCareer(name, balance.clamp(1, 100000000));
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
