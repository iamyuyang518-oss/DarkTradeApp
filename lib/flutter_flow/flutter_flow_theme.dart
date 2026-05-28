import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class FlutterFlowTheme {
  static FlutterFlowTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  Color get primary;
  Color get onPrimary;
  Color get primaryBackground;
  Color get secondaryBackground;
  Color get primaryText;
  Color get secondaryText;
  Color get alternate;
  Color get success;
  TextStyle get headlineMedium;
  TextStyle get labelLarge;
  TextStyle get labelSmall;
  TextStyle get bodyMedium;
}

class LightModeTheme extends FlutterFlowTheme {
  @override
  Color get primary => const Color(0xFF2563EB);

  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  @override
  Color get primaryBackground => const Color(0xFFF8FAFC);

  @override
  Color get secondaryBackground => const Color(0xFFFFFFFF);

  @override
  Color get primaryText => const Color(0xFF0F172A);

  @override
  Color get secondaryText => const Color(0xFF64748B);

  @override
  Color get alternate => const Color(0xFFE2E8F0);

  @override
  Color get success => const Color(0xFF16A34A);

  @override
  TextStyle get headlineMedium => GoogleFonts.inter(fontSize: 24);

  @override
  TextStyle get labelLarge => GoogleFonts.inter(fontSize: 14);

  @override
  TextStyle get labelSmall => GoogleFonts.inter(fontSize: 11);

  @override
  TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14);
}

class DarkModeTheme extends FlutterFlowTheme {
  @override
  Color get primary => const Color(0xFFFFD700);

  @override
  Color get onPrimary => const Color(0xFF0D0D0D);

  @override
  Color get primaryBackground => const Color(0xFF0D0D0D);

  @override
  Color get secondaryBackground => const Color(0xFF151515);

  @override
  Color get primaryText => const Color(0xFFF5F5F5);

  @override
  Color get secondaryText => const Color(0xFF9CA3AF);

  @override
  Color get alternate => const Color(0xFF2A2A2A);

  @override
  Color get success => const Color(0xFF22C55E);

  @override
  TextStyle get headlineMedium => GoogleFonts.inter(fontSize: 24);

  @override
  TextStyle get labelLarge => GoogleFonts.inter(fontSize: 14);

  @override
  TextStyle get labelSmall => GoogleFonts.inter(fontSize: 11);

  @override
  TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14);
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    Color? color,
    double? letterSpacing,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? lineHeight,
  }) {
    return copyWith(
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: lineHeight,
    ).merge(font);
  }
}
