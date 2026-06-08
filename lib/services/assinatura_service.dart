import '../database/database_helper.dart';
import '../models/assinatura.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class AssinaturaService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  AssinaturaService(this._db, this._conn, this._ctx);

  Future<List<Assinatura>> listar(String barbeariaId) async {
    final rows = await _db.query(
      'assinaturas',
      where: 'barbearia_id = ?',
      whereArgs: [barbeariaId],
      orderBy: 'data_vencimento DESC',
    );
    return rows.map(Assinatura.fromMap).toList();
  }

  Future<Assinatura?> buscarPorCliente(int clienteId) async {
    final rows = await _db.query(
      'assinaturas',
      where: "cliente_id = ? AND status = 'ativo'",
      whereArgs: [clienteId],
      orderBy: 'data_vencimento DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Assinatura.fromMap(rows.first);
  }

  Future<Assinatura> salvar(Assinatura assinatura) async {
    if (assinatura.valor <= 0) throw const ValidationException('Valor inválido.');

    final data = assinatura.toMap()..remove('id');
    int id;
    if (assinatura.id == null) {
      id = await _db.insert('assinaturas', data);

      // Mark client as subscriber
      await _db.rawQuery(
        'UPDATE clientes SET is_assinante = 1, atualizado_em = datetime(\'now\') WHERE id = ?',
        [assinatura.clienteId],
      );
    } else {
      await _db.update('assinaturas', data, assinatura.id!);
      id = assinatura.id!;
    }

    final saved = (await _db.query('assinaturas', where: 'id = ?', whereArgs: [id])).first;
    final result = Assinatura.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('assinaturas');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('assinaturas', {'firebase_id': fireId}, id);
        }
      }, context: 'AssinaturaService.salvar');
    }

    return result;
  }

  Future<void> cancelar(int id) async {
    await _db.update('assinaturas', {'status': 'cancelado'}, id);
    final rows = await _db.query('assinaturas', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final clienteId = rows.first['cliente_id'] as int;
      // Check if any other active subscription exists
      final outros = await _db.query(
        'assinaturas',
        where: "cliente_id = ? AND status = 'ativo' AND id != ?",
        whereArgs: [clienteId, id],
        limit: 1,
      );
      if (outros.isEmpty) {
        await _db.rawQuery(
          'UPDATE clientes SET is_assinante = 0, atualizado_em = datetime(\'now\') WHERE id = ?',
          [clienteId],
        );
      }
    }
  }

  Future<void> pausar(int id) async {
    await _db.update('assinaturas', {'status': 'pausado'}, id);
  }

  Future<void> reativar(int id) async {
    await _db.update('assinaturas', {'status': 'ativo'}, id);
  }

  Future<Map<String, dynamic>> kpis(String barbeariaId) async {
    final total = await _db.rawQuery(
      "SELECT COUNT(*) as cnt FROM assinaturas WHERE barbearia_id = ? AND status = 'ativo'",
      [barbeariaId],
    );
    final mrr = await _db.rawQuery(
      "SELECT COALESCE(SUM(valor), 0) as mrr FROM assinaturas WHERE barbearia_id = ? AND status = 'ativo'",
      [barbeariaId],
    );
    final vencendo = await _db.rawQuery(
      "SELECT COUNT(*) as cnt FROM assinaturas WHERE barbearia_id = ? AND status = 'ativo' AND date(data_vencimento) <= date('now', '+7 days')",
      [barbeariaId],
    );
    return {
      'total_ativas': (total.first['cnt'] as int?) ?? 0,
      'mrr': (mrr.first['mrr'] as num?)?.toDouble() ?? 0.0,
      'vencendo_em_7_dias': (vencendo.first['cnt'] as int?) ?? 0,
    };
  }
}
