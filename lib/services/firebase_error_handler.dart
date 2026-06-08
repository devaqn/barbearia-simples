import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract class FirebaseErrorHandler {
  static Future<T?> wrapSilent<T>(
    Future<T> Function() action, {
    String? context,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirebaseErrorHandler] $context: $e');
      try {
        await FirebaseCrashlytics.instance.recordError(e, st, reason: context);
      } catch (_) {}
      return null;
    }
  }

  static Future<T> wrap<T>(
    Future<T> Function() action, {
    String? context,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[FirebaseErrorHandler] $context: $e');
      try {
        await FirebaseCrashlytics.instance.recordError(e, st, reason: context);
      } catch (_) {}
      rethrow;
    }
  }
}
