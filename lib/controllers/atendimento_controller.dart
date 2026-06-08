import 'package:flutter/foundation.dart';
import '../models/atendimento.dart';
import '../services/atendimento_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class AtendimentoController extends ChangeNotifier with ControllerMixin {
  final AtendimentoService _svc;
  final SessionManager _session;

  List<Atendimento> atendimentos = [];

  AtendimentoController(this._svc, this._session);

  Future<void> carregar({DateTime? inicio, DateTime? fim, int? clienteId}) async {
    await runSilent(() async {
      atendimentos = await _svc.listar(
        barbeariaId: _session.barbeariaId,
        barbeiroId: _session.isAdmin ? null : _session.userId,
        clienteId: clienteId,
        inicio: inicio,
        fim: fim,
      );
    });
  }
}
