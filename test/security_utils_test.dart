import 'package:flutter_test/flutter_test.dart';
import 'package:barberos/utils/security_utils.dart';

void main() {
  group('SecurityUtils', () {
    group('sanitize', () {
      test('strips HTML tags', () {
        // Tags are removed; text content between tags is preserved
        expect(SecurityUtils.sanitize('<script>alert(1)</script>hello'), contains('hello'));
        expect(SecurityUtils.sanitize('<script>alert(1)</script>hello'), isNot(contains('<script>')));
      });

      test('trims whitespace', () {
        expect(SecurityUtils.sanitize('  hello  '), equals('hello'));
      });

      test('truncates to maxLength', () {
        final long = 'a' * 600;
        expect(SecurityUtils.sanitize(long).length, equals(500));
      });

      test('handles null input', () {
        expect(SecurityUtils.sanitize(null), equals(''));
      });

      test('removes SQL injection delimiters', () {
        final input = "1' OR '1'='1; DROP TABLE users--";
        final result = SecurityUtils.sanitize(input);
        // SQL delimiters are removed; keywords may remain as plain text
        expect(result.contains(';'), isFalse);
        expect(result.contains('--'), isFalse);
      });
    });

    group('isValidEmail', () {
      test('valid email passes', () {
        expect(SecurityUtils.isValidEmail('user@example.com'), isTrue);
      });

      test('invalid email fails', () {
        expect(SecurityUtils.isValidEmail('not-an-email'), isFalse);
        expect(SecurityUtils.isValidEmail('@missing.com'), isFalse);
        expect(SecurityUtils.isValidEmail(''), isFalse);
      });
    });

    group('isStrongPassword', () {
      test('strong password passes', () {
        expect(SecurityUtils.isStrongPassword('Str0ng!Pass'), isTrue);
      });

      test('short password fails', () {
        expect(SecurityUtils.isStrongPassword('Ab1!'), isFalse);
      });

      test('no uppercase fails', () {
        expect(SecurityUtils.isStrongPassword('str0ng!pass'), isFalse);
      });

      test('no symbol fails', () {
        expect(SecurityUtils.isStrongPassword('Str0ngPass'), isFalse);
      });
    });

    group('sanitizePrice', () {
      test('valid double', () {
        expect(SecurityUtils.sanitizePrice(10.5), equals(10.5));
      });

      test('negative returns zero', () {
        expect(SecurityUtils.sanitizePrice(-5.0), equals(0.0));
      });

      test('string parses correctly', () {
        expect(SecurityUtils.sanitizePrice('15,90'), equals(15.90));
      });

      test('null returns zero', () {
        expect(SecurityUtils.sanitizePrice(null), equals(0.0));
      });
    });
  });
}
