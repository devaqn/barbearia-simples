import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barberos/controllers/controller_mixin.dart';
import 'package:barberos/services/service_exceptions.dart';

class _TestController extends ChangeNotifier with ControllerMixin {
  int callCount = 0;

  Future<String?> doSilent(Future<String> Function() fn) {
    callCount++;
    return runSilent(fn);
  }

  Future<String?> doCatch(Future<String> Function() fn) {
    callCount++;
    return runCatch(fn);
  }
}

void main() {
  group('ControllerMixin', () {
    late _TestController ctrl;

    setUp(() => ctrl = _TestController());

    test('runSilent sets isLoading and returns result', () async {
      final result = await ctrl.doSilent(() async => 'ok');
      expect(result, equals('ok'));
      expect(ctrl.isLoading, isFalse);
      expect(ctrl.errorMsg, isNull);
    });

    test('runSilent sets errorMsg on ServiceException and returns null', () async {
      final result = await ctrl.doSilent(() async {
        throw const ServiceException('test error');
      });
      expect(result, isNull);
      expect(ctrl.errorMsg, equals('test error'));
      expect(ctrl.isLoading, isFalse);
    });

    test('runSilent sets generic errorMsg on unknown exception', () async {
      final result = await ctrl.doSilent(() async {
        throw Exception('random');
      });
      expect(result, isNull);
      expect(ctrl.errorMsg, isNotNull);
      expect(ctrl.isLoading, isFalse);
    });

    test('runCatch rethrows ServiceException', () async {
      expect(
        () => ctrl.doCatch(() async { throw const ValidationException('invalid'); }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('clearError resets errorMsg', () async {
      await ctrl.doSilent(() async { throw const ServiceException('err'); });
      expect(ctrl.errorMsg, isNotNull);
      ctrl.clearError();
      expect(ctrl.errorMsg, isNull);
    });
  });
}
