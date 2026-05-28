// lib/core/extensions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ContextExt on BuildContext {
  T read<T>() => Provider.of<T>(this, listen: false);
  T watch<T>() => Provider.of<T>(this, listen: true);
  MediaQueryData get mq => MediaQuery.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
}
