import 'package:flutter/material.dart';

class AppTheme {
  // Pure black for OLED ambient mode power saving
  static const Color canvasBackground = Colors.black;
  static const Color toolbarBackground = Color(0x22FFFFFF); // Glassmorphic
  static const Color toolbarBorder = Color(0x44FFFFFF);
  static const Color defaultStroke = Colors.white;
  static const Color accentGlow = Color(0xFF00FFCC);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: canvasBackground,
        colorScheme: const ColorScheme.dark(
          primary: accentGlow,
          surface: Colors.black,
        ),
        useMaterial3: true,
      );
}
