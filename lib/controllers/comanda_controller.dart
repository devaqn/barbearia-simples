import 'package:flutter/foundation.dart';
import '../models/comanda.dart';
import '../models/item_comanda.dart';
import '../services/comanda_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class ComandaController extends ChangeNotifier with ControllerMixin {
  final ComandaService _svc;
  final SessionManager _session;

  List<Comanda> comandas = [];
  Comanda? comandaAtiva;

  ComandaController(this._svc, this._session);

  Future<void> carregar({String? status}) async {
    await runSilent(() async {
      comandas = await _svc.listar(
        barbeariaId: _session.barbeariaId,
        barbeiroId: _session.isAdmin ? null : _session.userId,
        status: status,
      );
    });
  }

  Future<bool> abrir({int? clienteId, String? observacoes}) async {
    final comanda = await runSilent(() => _svc.abrir(
          barbeiroId: _session.userId!,
          barbeariaId: _session.barbeariaId,
          clienteId: clienteId,
          observacoes: observacoes,
        ));
    if (comanda != null) {
      comandaAtiva = comanda;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> adicionarItem(ItemComanda item) async {
    if (comandaAtiva == null) return false;
    final updated = await runSilent(() => _svc.adicionarItem(comandaAtiva!.id!, item));
    if (updated != null) {
      comandaAtiva = updated;
      return true;
    }
    return false;
  }

  Future<bool> removerItem(int itemId) async {
    if (comandaAtiva == null) return false;
    final updated = await runSilent(() => _svc.removerItem(itemId, comandaAtiva!.id!));
    if (updated != null) {
      comandaAtiva = updated;
      return true;
    }
    return false;
  }

  Future<bool> fechar(String formaPagamento) async {
    if (comandaAtiva == null) return false;
    final updated = await runSilent(() => _svc.fechar(
          comandaId: comandaAtiva!.id!,
          formaPagamento: formaPagamento,
        ));
    if (updated != null) {
      comandaAtiva = null;
      await carregar();
      return true;
    }
    return false;
  }

  Future<bool> cancelar() async {
    if (comandaAtiva == null) return false;
    await runSilent(() => _svc.cancelar(comandaAtiva!.id!));
    if (errorMsg == null) {
      comandaAtiva = null;
      await carregar();
      return true;
    }
    return false;
  }

  void setComandaAtiva(Comanda c) {
    comandaAtiva = c;
    notifyListeners();
  }
}
