import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/career_service.dart';
import '../pages/career_management_sheet.dart';

class CareerSelector extends StatelessWidget {
  const CareerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final careerService = context.watch<CareerService>();
    final career = careerService.activeCareer;
    if (career == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFFFFFFFF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const CareerManagementSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4A853).withAlpha(80)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports, color: Color(0xFFD4A853), size: 16),
            const SizedBox(width: 6),
            Text(
              career.name,
              style: const TextStyle(color: Color(0xFFD4A853), fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Color(0xFFD4A853), size: 18),
          ],
        ),
      ),
    );
  }
}
