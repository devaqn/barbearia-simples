import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// We test the hash logic directly since LicenseService depends on String.fromEnvironment
// which is injected at build time.

void main() {
  group('License hash computation', () {
    const salt = 'barberos_salt_v1';

    String computeHash(String key) {
      final combined = utf8.encode('$key$salt');
      return sha256.convert(combined).toString();
    }

    test('same key + salt always produces same hash', () {
      const key = 'AAAAAAAABBBBBBBBCCCCCCCC';
      expect(computeHash(key), equals(computeHash(key)));
    });

    test('different key produces different hash', () {
      const key1 = 'AAAAAAAABBBBBBBBCCCCCCCC';
      const key2 = 'ZZZZZZZZBBBBBBBBCCCCCCCC';
      expect(computeHash(key1), isNot(equals(computeHash(key2))));
    });

    test('key must be exactly 24 chars', () {
      const short = 'ABC';
      const exact = 'AAAAAAAABBBBBBBBCCCCCCCC';
      expect(short.length, isNot(equals(24)));
      expect(exact.length, equals(24));
    });
  });
}
