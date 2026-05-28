import 'package:dark_trade_app/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';

class CategoryChipModel extends FlutterFlowModel<CategoryChipWidget> {
  bool selected = false;

  void setSelected(bool value) {
    if (selected == value) return;
    selected = value;
    notifyListeners();
  }
}

class CategoryChipWidget extends StatefulWidget {
  const CategoryChipWidget({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<CategoryChipWidget> createState() => _CategoryChipWidgetState();
}

class _CategoryChipWidgetState extends State<CategoryChipWidget> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
