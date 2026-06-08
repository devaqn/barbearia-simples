import 'dart:math';

abstract class SecurityUtils {
  static const int _maxDefaultLength = 500;

  static String sanitize(String? input, {int maxLength = _maxDefaultLength}) {
    if (input == null) return '';
    var s = input.trim();
    s = s.replaceAll(RegExp(r'<[^>]*>'), ''); // strip HTML tags
    s = s.replaceAll("'", "\\'");
    s = s.replaceAll('"', '\\"');
    s = s.replaceAll(';', '');
    s = s.replaceAll('--', '');
    if (s.length > maxLength) s = s.substring(0, maxLength);
    return s;
  }

  static String sanitizeName(String? input) =>
      sanitize(input, maxLength: 100).replaceAll(RegExp('[^a-zA-ZÀ-ÿ0-9 \\-]'), '');

  static String sanitizePhone(String? input) =>
      sanitize(input, maxLength: 20).replaceAll(RegExp(r'[^\d\+\(\)\-\s]'), '');

  static String sanitizeEmail(String? input) =>
      sanitize(input, maxLength: 150).toLowerCase().trim();

  static String sanitizeNumeric(String? input) =>
      sanitize(input, maxLength: 20).replaceAll(RegExp(r'[^\d\.,\-]'), '');

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp('[!@#\$%^&*()_+=\\[\\]{}|;:,.<>?/`~\\\\-]').hasMatch(password);
    return hasUpper && hasLower && hasDigit && hasSymbol;
  }

  static double sanitizePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value < 0 ? 0.0 : value;
    if (value is int) return value < 0 ? 0.0 : value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
    return max(0.0, parsed);
  }

  static int sanitizeQuantity(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    final parsed = int.tryParse(value.toString()) ?? 0;
    return max(0, parsed);
  }
}
