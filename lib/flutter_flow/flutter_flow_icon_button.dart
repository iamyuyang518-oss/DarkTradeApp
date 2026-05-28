import 'package:flutter/material.dart';

class FlutterFlowIconButton extends StatelessWidget {
  const FlutterFlowIconButton({
    super.key,
    required this.borderRadius,
    required this.buttonSize,
    required this.fillColor,
    required this.icon,
    required this.onPressed,
  });

  final double borderRadius;
  final double buttonSize;
  final Color fillColor;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
