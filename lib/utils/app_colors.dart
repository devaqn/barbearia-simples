import 'package:flutter/material.dart';
import 'app_config.dart';

abstract class AppColors {
  // Dark theme
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkDivider = Color(0xFF2A2A4A);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0F0);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Gold for subscribers
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFE57F);

  // Payment methods
  static const Color pix = Color(0xFF32BCAD);
  static const Color credit = Color(0xFF5C6BC0);
  static const Color debit = Color(0xFF26A69A);
  static const Color cash = Color(0xFF66BB6A);

  static Color get primary => AppConfig.primaryColor;
}
