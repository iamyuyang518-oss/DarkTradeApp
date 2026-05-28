import 'package:flutter/material.dart';

import 'flutter_flow_model.dart';

export 'flutter_flow_model.dart';

void Function(VoidCallback)? _ffPageSetState;

/// Call from the page [State.initState] after [createModel], and clear in [dispose].
void registerFfmPageSetState(void Function(VoidCallback) setter) {
  _ffPageSetState = setter;
}

void unregisterFfmPageSetState() {
  _ffPageSetState = null;
}

/// Matches FlutterFlow generated callbacks: `updateCallback: () => safeSetState(() {})`.
void safeSetState(VoidCallback fn) {
  final s = _ffPageSetState;
  if (s != null) {
    s(fn);
  } else {
    fn();
  }
}

extension IterableWidgetX on Iterable<Widget> {
  List<Widget> divide(Widget t) {
    final out = <Widget>[];
    final it = iterator;
    if (!it.moveNext()) return out;
    out.add(it.current);
    while (it.moveNext()) {
      out.add(t);
      out.add(it.current);
    }
    return out;
  }
}

extension ListWidgetX on List<Widget> {
  List<Widget> divide(Widget t) => IterableWidgetX(this).divide(t);
}

Widget wrapWithModel<T extends FlutterFlowModel>({
  required T model,
  required VoidCallback updateCallback,
  required Widget child,
}) {
  return ListenableBuilder(
    listenable: model,
    builder: (context, _) => child,
  );
}

T createModel<T extends FlutterFlowModel>(
  BuildContext context,
  T Function() builder,
) {
  return builder();
}
