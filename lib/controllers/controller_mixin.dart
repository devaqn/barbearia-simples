import 'package:flutter/foundation.dart';
import '../services/service_exceptions.dart';

mixin ControllerMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMsg;

  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _errorMsg = null;
    notifyListeners();
  }

  /// Runs action; sets isLoading/errorMsg; never throws.
  Future<T?> runSilent<T>(Future<T> Function() action) async {
    _setLoading(true);
    _errorMsg = null;
    try {
      final result = await action();
      return result;
    } on ServiceException catch (e) {
      _errorMsg = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMsg = 'Erro inesperado. Tente novamente.';
      if (kDebugMode) debugPrint('[Controller] Unexpected: $e');
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Runs action; sets isLoading/errorMsg; rethrows ServiceException.
  Future<T?> runCatch<T>(Future<T> Function() action) async {
    _setLoading(true);
    _errorMsg = null;
    try {
      return await action();
    } on ServiceException catch (e) {
      _errorMsg = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMsg = 'Erro inesperado.';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Runs action; does NOT catch; always throws on error.
  Future<T> runOrThrow<T>(Future<T> Function() action) async {
    _setLoading(true);
    _errorMsg = null;
    try {
      return await action();
    } finally {
      _setLoading(false);
    }
  }
}
