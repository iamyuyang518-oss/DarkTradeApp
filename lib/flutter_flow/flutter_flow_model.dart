import 'package:flutter/material.dart';

abstract class FlutterFlowModel<W extends Widget> extends ChangeNotifier {
  void initState(BuildContext context) {}

  @override
  void dispose() {
    super.dispose();
  }
}
