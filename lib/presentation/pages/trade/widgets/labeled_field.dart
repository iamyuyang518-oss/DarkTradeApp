import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable labeled text field for number input with dark/gold theme.
/// Used as the base for both price and quantity inputs.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.accentGold = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool accentGold;

  OutlineInputBorder _border({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.gold.withValues(alpha: focused ? 0.55 : 0.28),
        width: focused ? 1.4 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: accentGold
                    ? AppColors.gold
                    : AppColors.textPrimary.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              hint,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]')),
          ],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          cursorColor: AppColors.gold,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.goldBg,
            hintText: '0.00',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.45),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: _border(),
            focusedBorder: _border(focused: true),
            border: _border(),
          ),
        ),
      ],
    );
  }
}
