import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

class SessionManager extends ChangeNotifier {
  Usuario? _currentUser;

  Usuario? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String get barbeariaId => _currentUser?.barbeariaId ?? '';
  int? get userId => _currentUser?.id;

  void setUser(Usuario user) {
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _currentUser = null;
    notifyListeners();
  }
}
