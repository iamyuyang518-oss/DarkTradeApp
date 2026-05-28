import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

class RiskDisclaimerDialog extends StatefulWidget {
  const RiskDisclaimerDialog({super.key});

  @override
  State<RiskDisclaimerDialog> createState() => _RiskDisclaimerDialogState();
}

class _RiskDisclaimerDialogState extends State<RiskDisclaimerDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: 8),
          Text(AppText.riskTitle, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppText.riskBody, style: TextStyle(height: 1.6)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppText.agreeTerms,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _agreed ? AppColors.gold : AppColors.unselectedBg,
            foregroundColor: Colors.white,
          ),
          onPressed: _agreed ? () => Navigator.of(context).pop(true) : null,
          child: const Text('确认并继续'),
        ),
      ],
    );
  }
}
