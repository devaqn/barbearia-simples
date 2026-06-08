import '../database/database_helper.dart';
import '../models/caixa.dart';
import 'service_exceptions.dart';

class CaixaService {
  final DatabaseHelper _db;

  CaixaService(this._db);

  Future<Caixa?> buscarAberto(int barbeiroId, String barbeariaId) async {
    final rows = await _db.query(
      'caixas',
      where: "barbeiro_id = ? AND barbearia_id = ? AND status = 'aberto'",
      whereArgs: [barbeiroId, barbeariaId],
      limit: 1,
    );
    return rows.isEmpty ? null : Caixa.fromMap(rows.first);
  }

  Future<Caixa> abrirCaixa({
    required int barbeiroId,
    required double saldoInicial,
    required String barbeariaId,
  }) async {
    final aberto = await buscarAberto(barbeiroId, barbeariaId);
    if (aberto != null) throw const ConflictException('Já existe um caixa aberto.');

    final id = await _db.insert('caixas', {
      'barbeiro_id': barbeiroId,
      'data_abertura': DateTime.now().toIso8601String(),
      'saldo_inicial': saldoInicial,
      'status': 'aberto',
      'barbearia_id': barbeariaId,
    });

    final rows = await _db.query('caixas', where: 'id = ?', whereArgs: [id]);
    return Caixa.fromMap(rows.first);
  }

  Future<Caixa> fecharCaixa(int caixaId, double saldoFinal, Map<String, double> resumo) async {
    await _db.update('caixas', {
      'data_fechamento': DateTime.now().toIso8601String(),
      'saldo_final': saldoFinal,
      'resumo_pagamentos_json': Caixa.encodeResumoStatic(resumo),
      'status': 'fechado',
    }, caixaId);
    final rows = await _db.query('caixas', where: 'id = ?', whereArgs: [caixaId]);
    return Caixa.fromMap(rows.first);
  }

  Future<Map<String, dynamic>> calcularTotais(int caixaId, String barbeariaId) async {
    final caixaRows = await _db.query('caixas', where: 'id = ?', whereArgs: [caixaId]);
    if (caixaRows.isEmpty) throw const NotFoundException('Caixa não encontrado.');
    final caixa = Caixa.fromMap(caixaRows.first);

    final fim = caixa.dataFechamento?.toIso8601String() ?? DateTime.now().toIso8601String();

    final totais = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) AS total_faturado,
        COUNT(*) AS total_comandas,
        COALESCE(SUM(CASE WHEN forma_pagamento = 'dinheiro' THEN total END), 0) AS dinheiro,
        COALESCE(SUM(CASE WHEN forma_pagamento = 'pix' THEN total END), 0) AS pix,
        COALESCE(SUM(CASE WHEN forma_pagamento = 'cartao_credito' THEN total END), 0) AS cartao_credito,
        COALESCE(SUM(CASE WHEN forma_pagamento = 'cartao_debito' THEN total END), 0) AS cartao_debito
      FROM comandas
      WHERE barbearia_id = ? AND status = 'fechada'
        AND data_fechamento >= ? AND data_fechamento <= ?
    ''', [barbeariaId, caixa.dataAbertura.toIso8601String(), fim]);

    return {
      ...totais.first,
      'saldo_inicial': caixa.saldoInicial,
      'saldo_final': caixa.saldoFinal,
    };
  }

  Future<List<Caixa>> listarHistorico(String barbeariaId, {int limit = 30}) async {
    final rows = await _db.query(
      'caixas',
      where: 'barbearia_id = ?',
      whereArgs: [barbeariaId],
      orderBy: 'data_abertura DESC',
      limit: limit,
    );
    return rows.map(Caixa.fromMap).toList();
  }
}
