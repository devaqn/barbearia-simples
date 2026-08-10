import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/avaliacao.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class AvaliacaoService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  AvaliacaoService(this._db, this._conn, this._ctx);

  Future<List<Avaliacao>> listarPorBarbearia(String barbeariaId) async {
    final rows = await _db.query(
      'avaliacoes',
      where: 'barbearia_id = ?',
      whereArgs: [barbeariaId],
      orderBy: 'criado_em DESC',
    );
    return rows.map(Avaliacao.fromMap).toList();
  }

  Future<List<Avaliacao>> listarPorBarbeiro(String barbeariaId, int barbeiroId) async {
    final rows = await _db.query(
      'avaliacoes',
      where: 'barbearia_id = ? AND barbeiro_id = ?',
      whereArgs: [barbeariaId, barbeiroId],
      orderBy: 'criado_em DESC',
    );
    return rows.map(Avaliacao.fromMap).toList();
  }

  Future<double> mediaPorBarbeiro(String barbeariaId, int barbeiroId) async {
    final rows = await _db.rawQuery(
      'SELECT AVG(nota) as media FROM avaliacoes WHERE barbearia_id = ? AND barbeiro_id = ?',
      [barbeariaId, barbeiroId],
    );
    if (rows.isEmpty || rows.first['media'] == null) return 0.0;
    return (rows.first['media'] as num).toDouble();
  }

  Future<Map<int, double>> mediasPorBarbearia(String barbeariaId) async {
    final rows = await _db.rawQuery(
      'SELECT barbeiro_id, AVG(nota) as media FROM avaliacoes WHERE barbearia_id = ? GROUP BY barbeiro_id',
      [barbeariaId],
    );
    final map = <int, double>{};
    for (final row in rows) {
      map[row['barbeiro_id'] as int] = (row['media'] as num).toDouble();
    }
    return map;
  }

  Future<Avaliacao> salvar(Avaliacao avaliacao) async {
    _validate(avaliacao);

    final data = avaliacao.toMap();
    if (data['criado_em'] == null) {
      data['criado_em'] = DateTime.now().toIso8601String();
    }
    data.remove('id');

    int id;
    if (avaliacao.id == null) {
      id = await _db.insert('avaliacoes', data);
    } else {
      await _db.update('avaliacoes', data, avaliacao.id!);
      id = avaliacao.id!;
    }

    final saved = (await _db.query('avaliacoes', where: 'id = ?', whereArgs: [id])).first;
    final result = Avaliacao.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('avaliacoes');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('avaliacoes', {'firebase_id': fireId}, id);
        }
      }, context: 'AvaliacaoService.salvar');
    }

    return result;
  }

  Future<void> excluir(int id) async {
    await _db.delete('avaliacoes', id);
  }

  void _validate(Avaliacao a) {
    if (a.nota < 1 || a.nota > 5) {
      throw const ValidationException('Nota deve ser entre 1 e 5.');
    }
    if (a.clienteId <= 0) {
      throw const ValidationException('Cliente obrigatório.');
    }
    if (a.barbeiroId <= 0) {
      throw const ValidationException('Barbeiro obrigatório.');
    }
  }
}
