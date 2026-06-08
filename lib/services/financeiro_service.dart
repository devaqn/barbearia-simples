import '../database/database_helper.dart';
import '../models/despesa.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class FinanceiroService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  FinanceiroService(this._db, this._conn, this._ctx);

  Future<Map<String, dynamic>> resumo({
    required String barbeariaId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final rows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS faturamento,
        COUNT(*) AS total_atendimentos
      FROM comandas
      WHERE barbearia_id = ? AND status = 'fechada'
        AND data_fechamento BETWEEN ? AND ?
    ''', [barbeariaId, inicio.toIso8601String(), fim.toIso8601String()]);

    final despesasRows = await _db.rawQuery('''
      SELECT COALESCE(SUM(valor), 0) AS total_despesas
      FROM despesas
      WHERE barbearia_id = ? AND data BETWEEN ? AND ?
    ''', [barbeariaId, inicio.toIso8601String(), fim.toIso8601String()]);

    final faturamento = (rows.first['faturamento'] as num?)?.toDouble() ?? 0.0;
    final despesas = (despesasRows.first['total_despesas'] as num?)?.toDouble() ?? 0.0;

    return {
      'faturamento': faturamento,
      'despesas': despesas,
      'lucro': faturamento - despesas,
      'total_atendimentos': (rows.first['total_atendimentos'] as int?) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> faturamentoPorDia({
    required String barbeariaId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    return _db.rawQuery('''
      SELECT strftime('%Y-%m-%d', data_fechamento) AS dia,
             SUM(total) AS valor
      FROM comandas
      WHERE barbearia_id = ? AND status = 'fechada'
        AND data_fechamento BETWEEN ? AND ?
      GROUP BY dia
      ORDER BY dia ASC
    ''', [barbeariaId, inicio.toIso8601String(), fim.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> faturamentoPorFormaPagamento({
    required String barbeariaId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    return _db.rawQuery('''
      SELECT forma_pagamento, SUM(total) AS valor, COUNT(*) AS quantidade
      FROM comandas
      WHERE barbearia_id = ? AND status = 'fechada'
        AND data_fechamento BETWEEN ? AND ?
      GROUP BY forma_pagamento
    ''', [barbeariaId, inicio.toIso8601String(), fim.toIso8601String()]);
  }

  // Despesas

  Future<List<Despesa>> listarDespesas(String barbeariaId) async {
    final rows = await _db.query(
      'despesas',
      where: 'barbearia_id = ?',
      whereArgs: [barbeariaId],
      orderBy: 'data DESC',
    );
    return rows.map(Despesa.fromMap).toList();
  }

  Future<Despesa> salvarDespesa(Despesa despesa) async {
    if (despesa.descricao.trim().isEmpty) {
      throw const ValidationException('Descrição obrigatória.');
    }
    if (despesa.valor <= 0) {
      throw const ValidationException('Valor deve ser positivo.');
    }

    final data = despesa.toMap()..remove('id');
    int id;
    if (despesa.id == null) {
      id = await _db.insert('despesas', data);
    } else {
      await _db.update('despesas', data, despesa.id!);
      id = despesa.id!;
    }

    final saved = (await _db.query('despesas', where: 'id = ?', whereArgs: [id])).first;
    final result = Despesa.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('despesas');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('despesas', {'firebase_id': fireId}, id);
        }
      }, context: 'FinanceiroService.salvarDespesa');
    }

    return result;
  }

  Future<void> excluirDespesa(int id) async => _db.delete('despesas', id);

  Future<List<Map<String, dynamic>>> rankingBarbeiros({
    required String barbeariaId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    return _db.rawQuery('''
      SELECT u.id, u.nome,
             COALESCE(SUM(c.total), 0) AS faturamento,
             COALESCE(SUM(cm.valor), 0) AS comissao
      FROM usuarios u
      LEFT JOIN comandas c ON c.barbeiro_id = u.id
        AND c.status = 'fechada'
        AND c.barbearia_id = ?
        AND c.data_fechamento BETWEEN ? AND ?
      LEFT JOIN comissoes cm ON cm.barbeiro_id = u.id
        AND cm.barbearia_id = ?
        AND cm.data BETWEEN ? AND ?
      WHERE u.barbearia_id = ? AND u.ativo = 1
      GROUP BY u.id
      ORDER BY faturamento DESC
    ''', [
      barbeariaId,
      inicio.toIso8601String(),
      fim.toIso8601String(),
      barbeariaId,
      inicio.toIso8601String(),
      fim.toIso8601String(),
      barbeariaId,
    ]);
  }
}
