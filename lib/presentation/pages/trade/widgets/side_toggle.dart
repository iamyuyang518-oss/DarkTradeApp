import 'package:flutter/material.dart';

/// Buy / Sell toggle bar with animated selection indicator.
class SideToggle extends StatelessWidget {
  const SideToggle({super.key, required this.isBuy, required this.onChanged});

  static const Color _gold = Color(0xFFFFD700);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _idleBg = Color(0xFF1E1E1E);
  static const Color _idleText = Color(0xFF6B6B6B);

  final bool isBuy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _idleBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleCell(
              label: '买入',
              selected: isBuy,
              selectedColor: _green,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleCell(
              label: '卖出',
              selected: !isBuy,
              selectedColor: _red,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCell extends StatelessWidget {
  const _ToggleCell({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        splashColor: selectedColor.withValues(alpha: 0.25),
        highlightColor: selectedColor.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? selectedColor : SideToggle._idleBg,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : SideToggle._idleText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
