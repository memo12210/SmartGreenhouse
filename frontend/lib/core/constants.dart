import 'dart:io';
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0D120D);
  static const Color neonGreen = Color(0xFFB6FF5B);
  static const Color textGrey = Color(0xFF8A8F8A);
  static const Color cardGrey = Color(0xFF1A1F1A);
  static const Color borderWhite = Color(0x1AFFFFFF);
}

class MqttConfig {
  // Use 10.0.2.2 for Android emulator to connect to host machine's localhost.
  static String get host => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  static const int port = 1883;
  static const String topic = 'greenhouses/';
}

class ApiConfig {
  static String get baseUrl => Platform.isAndroid ? 'http://10.0.2.2:8000/api/v1' : 'http://127.0.0.1:8000/api/v1';
}

class AppGradients {
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF030504),
      Color(0xFF08150D),
      Color(0xFF0D120D),
      Color(0xFF122318),
    ],
    stops: [0.0, 0.28, 0.68, 1.0],
  );
}