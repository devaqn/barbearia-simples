import 'package:flutter/material.dart';

abstract class AppConfig {
  static const String appName = 'BarberOS';
  static const String tagline = 'Gestão profissional para barbearias';
  static const String version = '1.0.0';
  static const String logoAsset = 'assets/images/logo.png';

  static const String _primaryColorHex = String.fromEnvironment(
    'PRIMARY_COLOR',
    defaultValue: 'FF4A4AFF',
  );

  static const String licenseHash = String.fromEnvironment('LICENSE_HASH');
  static const String licenseSalt = String.fromEnvironment('LICENSE_SALT', defaultValue: 'barberos_salt_v1');

  static Color get primaryColor {
    final hex = _primaryColorHex.replaceAll('#', '');
    try {
      final value = int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      return Color(value);
    } catch (_) {
      return const Color(0xFF4A4AFF);
    }
  }
}
