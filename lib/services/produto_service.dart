import '../database/database_helper.dart';
import '../models/produto.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class ProdutoService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  ProdutoService(this._db, this._conn, this._ctx);

  Future<List<Produto>> listar(String barbeariaId) async {
    final rows = await _db.query(
      'produtos',
      where: 'barbearia_id = ?',
      whereArgs: [barbeariaId],
      orderBy: 'nome ASC',
    );
    return rows.map(Produto.fromMap).toList();
  }

  Future<List<Produto>> alertasEstoque(String barbeariaId) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM produtos WHERE barbearia_id = ? AND quantidade <= estoque_minimo ORDER BY quantidade ASC',
      [barbeariaId],
    );
    return rows.map(Produto.fromMap).toList();
  }

  Future<Produto?> buscarPorId(int id) async {
    final rows = await _db.query('produtos', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Produto.fromMap(rows.first);
  }

  Future<Produto> salvar(Produto produto) async {
    _validate(produto);
    final data = produto.toMap()..remove('id');

    int id;
    if (produto.id == null) {
      id = await _db.insert('produtos', data);
    } else {
      await _db.update('produtos', data, produto.id!);
      id = produto.id!;
    }

    final saved = (await _db.query('produtos', where: 'id = ?', whereArgs: [id])).first;
    final result = Produto.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('produtos');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('produtos', {'firebase_id': fireId}, id);
        }
      }, context: 'ProdutoService.salvar');
    }

    return result;
  }

  Future<void> entradaEstoque({
    required int produtoId,
    required int quantidade,
    required double custoUnitario,
    required String barbeariaId,
    String? observacoes,
  }) async {
    await _db.transaction((txn) async {
      final rows = await txn.query('produtos', where: 'id = ?', whereArgs: [produtoId]);
      if (rows.isEmpty) throw const NotFoundException('Produto não encontrado.');
      final produto = Produto.fromMap(rows.first);

      final novaQtd = produto.quantidade + quantidade;
      final novoCustoMedio = novaQtd == 0
          ? 0.0
          : ((produto.custoMedio * produto.quantidade) + (custoUnitario * quantidade)) / novaQtd;

      await txn.update(
        'produtos',
        {'quantidade': novaQtd, 'custo_medio': novoCustoMedio},
        where: 'id = ?',
        whereArgs: [produtoId],
      );

      await txn.insert('movimentos_estoque', {
        'produto_id': produtoId,
        'tipo': 'entrada',
        'quantidade': quantidade,
        'custo_unitario': custoUnitario,
        'observacoes': observacoes,
        'data_hora': DateTime.now().toIso8601String(),
        'barbearia_id': barbeariaId,
      });
    });
  }

  Future<void> baixaEstoque({
    required int produtoId,
    required int quantidade,
    required String barbeariaId,
    String? observacoes,
  }) async {
    await _db.transaction((txn) async {
      final rows = await txn.query('produtos', where: 'id = ?', whereArgs: [produtoId]);
      if (rows.isEmpty) throw const NotFoundException('Produto não encontrado.');
      final produto = Produto.fromMap(rows.first);

      if (produto.quantidade < quantidade) {
        throw ValidationException('Estoque insuficiente para ${produto.nome}.');
      }

      await txn.update(
        'produtos',
        {'quantidade': produto.quantidade - quantidade},
        where: 'id = ?',
        whereArgs: [produtoId],
      );

      await txn.insert('movimentos_estoque', {
        'produto_id': produtoId,
        'tipo': 'saida',
        'quantidade': quantidade,
        'custo_unitario': produto.custoMedio,
        'observacoes': observacoes,
        'data_hora': DateTime.now().toIso8601String(),
        'barbearia_id': barbeariaId,
      });
    });
  }

  Future<List<Map<String, dynamic>>> rankingMaisVendidos(
    String barbeariaId, {
    int limit = 10,
  }) async {
    return _db.rawQuery('''
      SELECT p.id, p.nome, SUM(ci.quantidade) AS total_vendido
      FROM comandas_itens ci
      JOIN comandas c ON c.id = ci.comanda_id
      JOIN produtos p ON p.id = ci.referencia_id
      WHERE ci.tipo = 'produto' AND c.barbearia_id = ? AND c.status = 'fechada'
      GROUP BY p.id
      ORDER BY total_vendido DESC
      LIMIT ?
    ''', [barbeariaId, limit]);
  }

  void _validate(Produto p) {
    if (p.nome.trim().isEmpty) throw const ValidationException('Nome obrigatório.');
    if (p.precoVenda <= 0) throw const ValidationException('Preço de venda inválido.');
  }
}
