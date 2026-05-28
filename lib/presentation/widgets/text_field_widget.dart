import 'package:dark_trade_app/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';

class TextFieldModel extends FlutterFlowModel<TextFieldWidget> {
  late TextEditingController controller;

  @override
  void initState(BuildContext context) {
    super.initState(context);
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.label,
    required this.labelPresent,
    required this.helper,
    required this.helperPresent,
    required this.hint,
    required this.value,
    this.onChange,
    this.onSubmit,
    this.leadingIcon,
    required this.leadingIconPresent,
    required this.trailingIconPresent,
    required this.variant,
    required this.error,
    required this.controller,
  });

  final String label;
  final bool labelPresent;
  final String helper;
  final bool helperPresent;
  final String hint;
  final String value;
  final void Function(String)? onChange;
  final void Function(String)? onSubmit;
  final Widget? leadingIcon;
  final bool leadingIconPresent;
  final bool trailingIconPresent;
  final String variant;
  final bool error;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelPresent ? label : null,
        hintText: hint,
        helperText: helperPresent ? helper : null,
        prefixIcon: leadingIconPresent ? leadingIcon : null,
        filled: variant == 'filled',
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error ? Theme.of(context).colorScheme.error : Theme.of(context).dividerColor,
          ),
        ),
      ),
      onChanged: onChange,
      onSubmitted: onSubmit,
    );
  }
}
