import 'package:flutter/foundation.dart';
import '../models/servico.dart';
import '../services/servico_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class ServicoController extends ChangeNotifier with ControllerMixin {
  final ServicoService _svc;
  final SessionManager _session;

  List<Servico> servicos = [];

  ServicoController(this._svc, this._session);

  Future<void> carregar({bool somenteAtivos = true}) async {
    await runSilent(() async {
      servicos = await _svc.listar(_session.barbeariaId, somenteAtivos: somenteAtivos);
    });
  }

  Future<bool> salvar(Servico servico) async {
    final result = await runSilent(() => _svc.salvar(servico));
    if (result != null) await carregar(somenteAtivos: false);
    return result != null;
  }

  Future<void> toggleAtivo(Servico servico) async {
    await runSilent(() async {
      if (servico.ativo) {
        await _svc.desativar(servico.id!);
      } else {
        await _svc.ativar(servico.id!);
      }
    });
    await carregar(somenteAtivos: false);
  }
}
