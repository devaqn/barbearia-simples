import '../database/database_helper.dart';

class DashboardService {
  final DatabaseHelper _db;

  DashboardService(this._db);

  Future<Map<String, dynamic>> resumoAdmin(String barbeariaId) async {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemana = inicioHoje.subtract(Duration(days: hoje.weekday - 1));
    final inicioMes = DateTime(hoje.year, hoje.month, 1);

    final kpiRows = await _db.rawQuery('''
      SELECT
        COUNT(CASE WHEN data_fechamento >= ? THEN 1 END) AS atendimentos_hoje,
        COALESCE(SUM(CASE WHEN data_fechamento >= ? THEN total END), 0) AS faturamento_hoje,
        COUNT(CASE WHEN data_fechamento >= ? THEN 1 END) AS atendimentos_semana,
        COALESCE(SUM(CASE WHEN data_fechamento >= ? THEN total END), 0) AS faturamento_semana,
        COUNT(CASE WHEN data_fechamento >= ? THEN 1 END) AS atendimentos_mes,
        COALESCE(SUM(CASE WHEN data_fechamento >= ? THEN total END), 0) AS faturamento_mes
      FROM comandas
      WHERE barbearia_id = ? AND status = 'fechada'
    ''', [
      inicioHoje.toIso8601String(),
      inicioHoje.toIso8601String(),
      inicioSemana.toIso8601String(),
      inicioSemana.toIso8601String(),
      inicioMes.toIso8601String(),
      inicioMes.toIso8601String(),
      barbeariaId,
    ]);

    final aniversarios = await _db.rawQuery(
      "SELECT COUNT(*) as cnt FROM clientes WHERE barbearia_id = ? AND strftime('%m-%d', data_nascimento) = strftime('%m-%d', 'now')",
      [barbeariaId],
    );

    final estoqueAlerta = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM produtos WHERE barbearia_id = ? AND quantidade <= estoque_minimo',
      [barbeariaId],
    );

    final assinaturasAtivas = await _db.rawQuery(
      "SELECT COUNT(*) as cnt FROM assinaturas WHERE barbearia_id = ? AND status = 'ativo'",
      [barbeariaId],
    );

    return {
      ...kpiRows.first,
      'aniversariantes_hoje': (aniversarios.first['cnt'] as int?) ?? 0,
      'alertas_estoque': (estoqueAlerta.first['cnt'] as int?) ?? 0,
      'assinaturas_ativas': (assinaturasAtivas.first['cnt'] as int?) ?? 0,
    };
  }

  Future<Map<String, dynamic>> resumoBarbeiro(int barbeiroId, String barbeariaId) async {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioMes = DateTime(hoje.year, hoje.month, 1);

    final rows = await _db.rawQuery('''
      SELECT
        COUNT(CASE WHEN data_fechamento >= ? THEN 1 END) AS atendimentos_hoje,
        COALESCE(SUM(CASE WHEN data_fechamento >= ? THEN total END), 0) AS faturamento_hoje,
        COUNT(CASE WHEN data_fechamento >= ? THEN 1 END) AS atendimentos_mes,
        COALESCE(SUM(CASE WHEN data_fechamento >= ? THEN total END), 0) AS faturamento_mes
      FROM comandas
      WHERE barbeiro_id = ? AND barbearia_id = ? AND status = 'fechada'
    ''', [
      inicioHoje.toIso8601String(),
      inicioHoje.toIso8601String(),
      inicioMes.toIso8601String(),
      inicioMes.toIso8601String(),
      barbeiroId,
      barbeariaId,
    ]);

    final comissaoPendente = await _db.rawQuery(
      'SELECT COALESCE(SUM(valor), 0) as total FROM comissoes WHERE barbeiro_id = ? AND pago = 0 AND barbearia_id = ?',
      [barbeiroId, barbeariaId],
    );

    return {
      ...rows.first,
      'comissao_pendente': (comissaoPendente.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
