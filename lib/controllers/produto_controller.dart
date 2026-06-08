import 'package:flutter/foundation.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';
import '../services/session_manager.dart';
import 'controller_mixin.dart';

class ProdutoController extends ChangeNotifier with ControllerMixin {
  final ProdutoService _svc;
  final SessionManager _session;

  List<Produto> produtos = [];
  List<Produto> alertasEstoque = [];

  ProdutoController(this._svc, this._session);

  Future<void> carregar() async {
    await runSilent(() async {
      produtos = await _svc.listar(_session.barbeariaId);
      alertasEstoque = await _svc.alertasEstoque(_session.barbeariaId);
    });
  }

  Future<bool> salvar(Produto produto) async {
    final result = await runSilent(() => _svc.salvar(produto));
    if (result != null) await carregar();
    return result != null;
  }

  Future<bool> entradaEstoque({
    required int produtoId,
    required int quantidade,
    required double custo,
    String? obs,
  }) async {
    await runSilent(() => _svc.entradaEstoque(
          produtoId: produtoId,
          quantidade: quantidade,
          custoUnitario: custo,
          barbeariaId: _session.barbeariaId,
          observacoes: obs,
        ));
    if (errorMsg == null) {
      await carregar();
      return true;
    }
    return false;
  }
}
