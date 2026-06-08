import 'package:flutter/foundation.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class ClienteController extends ChangeNotifier with ControllerMixin {
  final ClienteService _svc;
  final SessionManager _session;

  List<Cliente> clientes = [];
  List<Cliente> aniversariantes = [];

  ClienteController(this._svc, this._session);

  Future<void> carregar({String? busca}) async {
    await runSilent(() async {
      clientes = await _svc.listar(_session.barbeariaId, busca: busca);
    });
  }

  Future<void> carregarAniversariantes() async {
    await runSilent(() async {
      aniversariantes = await _svc.aniversariantesHoje(_session.barbeariaId);
    });
  }

  Future<bool> salvar(Cliente cliente) async {
    final result = await runSilent(() => _svc.salvar(cliente));
    if (result != null) await carregar();
    return result != null;
  }

  Future<bool> excluir(int id) async {
    await runSilent(() => _svc.excluir(id));
    if (errorMsg == null) {
      clientes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<List<Cliente>> rankingMelhores() async {
    return _svc.rankingMelhores(_session.barbeariaId);
  }

  Future<List<Cliente>> clientesSumidos() async {
    return _svc.clientesSumidos(_session.barbeariaId);
  }
}
