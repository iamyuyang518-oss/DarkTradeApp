import 'package:flutter/material.dart';

/// Row of quick-percentage chips (25% / 50% / 75% / 100%) that fill the
/// quantity field based on max affordable/available amount.
class QuickPositionChips extends StatelessWidget {
  const QuickPositionChips({super.key, required this.onPercentTap});

  static const Color _gold = Color(0xFFFFD700);

  final ValueChanged<double> onPercentTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickChip(label: '25%', onTap: () => onPercentTap(0.25)),
        const SizedBox(width: 10),
        _QuickChip(label: '50%', onTap: () => onPercentTap(0.50)),
        const SizedBox(width: 10),
        _QuickChip(label: '75%', onTap: () => onPercentTap(0.75)),
        const SizedBox(width: 10),
        _QuickChip(label: '100%', onTap: () => onPercentTap(1.0)),
      ],
    );
  }
}

class _QuickChip extends StatefulWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _c.forward(from: 0);
    await _c.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.94).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        ),
        child: Material(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _tap,
            borderRadius: BorderRadius.circular(8),
            splashColor: QuickPositionChips._gold.withValues(alpha: 0.18),
            highlightColor: QuickPositionChips._gold.withValues(alpha: 0.08),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: QuickPositionChips._gold.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: QuickPositionChips._gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
