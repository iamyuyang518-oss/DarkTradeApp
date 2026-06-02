import 'package:dark_trade_app/core/constants.dart';
import 'package:flutter/material.dart';

/// Card wrapper that adds hover lift + golden border effect on web.
class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final double? borderRadius;
  final VoidCallback? onTap;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppDimens.radiusLg;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _hovered ? -2.0 : 0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: _hovered ? AppColors.gold : AppColors.border,
                width: 1.5,
              ),
              boxShadow: _hovered ? AppShadows.hover : AppShadows.card,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
