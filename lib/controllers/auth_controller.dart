import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class AuthController extends ChangeNotifier with ControllerMixin {
  final AuthService _authSvc;
  final SessionManager _session;

  AuthController(this._authSvc, this._session);

  Future<bool> login(String email, String password) async {
    final user = await runSilent(() => _authSvc.signIn(email, password));
    if (user == null) return false;
    if (user.revoked) {
      errorMsg;
      return false;
    }
    _session.setUser(user);
    return true;
  }

  Future<void> logout() async {
    await runSilent(() => _authSvc.signOut());
    _session.clear();
  }

  Future<bool> sendPasswordReset(String email) async {
    await runSilent(() => _authSvc.sendPasswordReset(email));
    return errorMsg == null;
  }

  Future<bool> criarBarbeiro({
    required String email,
    required String password,
    required String nome,
    required double comissao,
  }) async {
    final uid = await runSilent(() => _authSvc.createBarbeiro(
          email: email,
          password: password,
          nome: nome,
          comissaoPercentual: comissao,
          barbeariaId: _session.barbeariaId,
        ));
    return uid != null;
  }

  Future<bool> bootstrapAdmin({
    required String email,
    required String password,
    required String nome,
    required String barbeariaId,
  }) async {
    final uid = await runSilent(() => _authSvc.bootstrapAdmin(
          email: email,
          password: password,
          nome: nome,
          barbeariaId: barbeariaId,
        ));
    return uid != null;
  }

  Future<bool> changePassword(String newPassword) async {
    await runSilent(() => _authSvc.changePassword(newPassword));
    return errorMsg == null;
  }
}
