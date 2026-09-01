import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color neonGreen = Color(0xFFC0FF00);
  static const Color backgroundBlack = Color(0xFF0A0D0A);
  static const Color surfaceDark = Color(0xFF111611);
  static const Color cardGrey = Color(0xFF1A1F1A);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  static const Color errorRed = Color(0xFFFF5252);
  static const Color warningOrange = Color(0xFFFFAB40);
  static const Color infoBlue = Color(0xFF448AFF);
  static const Color successGreen = Color(0xFF69F0AE);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F1A0F),
      Color(0xFF0A0D0A),
    ],
  );
}
