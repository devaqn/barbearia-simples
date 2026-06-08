import 'package:flutter/foundation.dart';
import '../models/despesa.dart';
import '../services/financeiro_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class FinanceiroController extends ChangeNotifier with ControllerMixin {
  final FinanceiroService _svc;
  final SessionManager _session;

  Map<String, dynamic> resumo = {};
  List<Despesa> despesas = [];
  List<Map<String, dynamic>> faturamentoDiario = [];
  List<Map<String, dynamic>> rankingBarbeiros = [];

  DateTime periodoInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime periodoFim = DateTime.now();

  FinanceiroController(this._svc, this._session);

  Future<void> carregarResumo() async {
    await runSilent(() async {
      resumo = await _svc.resumo(
        barbeariaId: _session.barbeariaId,
        inicio: periodoInicio,
        fim: periodoFim,
      );
      faturamentoDiario = await _svc.faturamentoPorDia(
        barbeariaId: _session.barbeariaId,
        inicio: periodoInicio,
        fim: periodoFim,
      );
      rankingBarbeiros = await _svc.rankingBarbeiros(
        barbeariaId: _session.barbeariaId,
        inicio: periodoInicio,
        fim: periodoFim,
      );
    });
  }

  Future<void> carregarDespesas() async {
    await runSilent(() async {
      despesas = await _svc.listarDespesas(_session.barbeariaId);
    });
  }

  Future<bool> salvarDespesa(Despesa despesa) async {
    final result = await runSilent(() => _svc.salvarDespesa(despesa));
    if (result != null) await carregarDespesas();
    return result != null;
  }

  Future<bool> excluirDespesa(int id) async {
    await runSilent(() => _svc.excluirDespesa(id));
    if (errorMsg == null) {
      despesas.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  void setPeriodo(DateTime inicio, DateTime fim) {
    periodoInicio = inicio;
    periodoFim = fim;
    notifyListeners();
  }
}
