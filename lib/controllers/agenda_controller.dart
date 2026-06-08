import 'package:flutter/foundation.dart';
import '../models/agendamento.dart';
import '../services/agenda_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class AgendaController extends ChangeNotifier with ControllerMixin {
  final AgendaService _svc;
  final SessionManager _session;

  List<Agendamento> agendamentos = [];
  DateTime diaSelecionado = DateTime.now();

  AgendaController(this._svc, this._session);

  Future<void> carregarDia(DateTime dia) async {
    diaSelecionado = dia;
    await runSilent(() async {
      agendamentos = await _svc.listarDia(
        _session.barbeariaId,
        dia,
        barbeiroId: _session.isAdmin ? null : _session.userId,
      );
    });
  }

  Future<bool> salvar(Agendamento ag) async {
    final result = await runSilent(() => _svc.salvar(ag));
    if (result != null) await carregarDia(diaSelecionado);
    return result != null;
  }

  Future<void> atualizarStatus(int id, String status) async {
    await runSilent(() => _svc.atualizarStatus(id, status));
    await carregarDia(diaSelecionado);
  }
}
