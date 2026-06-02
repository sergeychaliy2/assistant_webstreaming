import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDeep = Color(0xFF0B1220);
  static const Color bgMid = Color(0xFF101A2E);
  static const Color bgSoft = Color(0xFF152141);
  static const Color accentOrange = Color(0xFFFF8A3D);
  static const Color accentOrangeDark = Color(0xFFE0681F);
  static const Color accentBlue = Color(0xFF2B4FA0);
  static const Color glassStroke = Color(0x33FFFFFF);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassFillStrong = Color(0x22FFFFFF);
  static const Color textPrimary = Color(0xFFE6ECF8);
  static const Color textSecondary = Color(0xB3B7C0D8);

  static const double micButtonBigSize = 124;
  static const double micButtonSmallSize = 64;
  static const double playButtonSize = 150;
  static const double glassBlurSigma = 22;
  static const Duration micMoveDuration = Duration(milliseconds: 420);
  static const Curve micMoveCurve = Curves.easeInOutCubic;

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDeep, bgMid, bgSoft],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, accentOrangeDark],
  );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: accentOrange,
          secondary: accentBlue,
          surface: bgMid,
        ),
        scaffoldBackgroundColor: bgDeep,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: textPrimary),
          bodyLarge: TextStyle(color: textPrimary),
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );
}
