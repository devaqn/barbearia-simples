import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';
import '../utils/security_utils.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class ClienteService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  ClienteService(this._db, this._conn, this._ctx);

  Future<List<Cliente>> listar(String barbeariaId, {String? busca}) async {
    String? where = 'barbearia_id = ?';
    List<Object?> args = [barbeariaId];

    if (busca != null && busca.isNotEmpty) {
      final q = SecurityUtils.sanitize(busca);
      where = "barbearia_id = ? AND (nome LIKE ? OR telefone LIKE ?)";
      args = [barbeariaId, '%$q%', '%$q%'];
    }

    final rows = await _db.query('clientes', where: where, whereArgs: args, orderBy: 'nome ASC');
    return rows.map(Cliente.fromMap).toList();
  }

  Future<Cliente?> buscarPorId(int id) async {
    final rows = await _db.query('clientes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Cliente.fromMap(rows.first);
  }

  Future<Cliente> salvar(Cliente cliente) async {
    _validate(cliente);

    final data = cliente.toMap();
    data['atualizado_em'] = DateTime.now().toIso8601String();
    if (data['criado_em'] == null) {
      data['criado_em'] = DateTime.now().toIso8601String();
    }
    data.remove('id');

    int id;
    if (cliente.id == null) {
      id = await _db.insert('clientes', data);
    } else {
      await _db.update('clientes', data, cliente.id!);
      id = cliente.id!;
    }

    final saved = (await _db.query('clientes', where: 'id = ?', whereArgs: [id])).first;
    final result = Cliente.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('clientes');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('clientes', {'firebase_id': fireId}, id);
        }
      }, context: 'ClienteService.salvar');
    }

    return result;
  }

  Future<void> excluir(int id) async {
    await _db.delete('clientes', id);
  }

  Future<List<Cliente>> aniversariantesHoje(String barbeariaId) async {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final rows = await _db.rawQuery(
      "SELECT * FROM clientes WHERE barbearia_id = ? AND strftime('%m-%d', data_nascimento) = ?",
      [barbeariaId, '$month-$day'],
    );
    return rows.map(Cliente.fromMap).toList();
  }

  Future<List<Cliente>> clientesSumidos(String barbeariaId, {int diasSemVir = 60}) async {
    final rows = await _db.rawQuery('''
      SELECT c.* FROM clientes c
      LEFT JOIN atendimentos a ON a.cliente_id = c.id
      WHERE c.barbearia_id = ?
      GROUP BY c.id
      HAVING MAX(a.data_hora) IS NULL
         OR (julianday('now') - julianday(MAX(a.data_hora))) > ?
      ORDER BY c.total_gasto DESC
      LIMIT 50
    ''', [barbeariaId, diasSemVir]);
    return rows.map(Cliente.fromMap).toList();
  }

  Future<List<Cliente>> rankingMelhores(String barbeariaId, {int limit = 10}) async {
    final rows = await _db.query(
      'clientes',
      where: 'barbearia_id = ?',
      whereArgs: [barbeariaId],
      orderBy: 'total_gasto DESC',
      limit: limit,
    );
    return rows.map(Cliente.fromMap).toList();
  }

  void _validate(Cliente c) {
    if (c.nome.trim().isEmpty) throw const ValidationException('Nome obrigatório.');
    if (c.telefone.trim().isEmpty) throw const ValidationException('Telefone obrigatório.');
    if (c.email != null && c.email!.isNotEmpty && !SecurityUtils.isValidEmail(c.email!)) {
      throw const ValidationException('E-mail inválido.');
    }
  }

  Future<void> atualizarFidelidade(
    int clienteId, {
    required double valorAdicionado,
    int atendimentosAdicionados = 1,
  }) async {
    if (kDebugMode) debugPrint('[ClienteService] Fidelidade cliente $clienteId +$valorAdicionado');
    await _db.rawQuery('''
      UPDATE clientes
      SET total_atendimentos = total_atendimentos + ?,
          total_gasto = total_gasto + ?,
          pontos_fidelidade = pontos_fidelidade + ?,
          atualizado_em = datetime('now')
      WHERE id = ?
    ''', [
      atendimentosAdicionados,
      valorAdicionado,
      valorAdicionado.toInt(),
      clienteId,
    ]);
  }
}
