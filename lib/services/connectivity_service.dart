import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _update(result);
    } catch (e) {
      if (kDebugMode) debugPrint('[Connectivity] Init error: $e');
    }
    _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      if (kDebugMode) debugPrint('[Connectivity] Online: $_isOnline');
      notifyListeners();
    }
  }
}
