import '../database/database_helper.dart';
import '../models/servico.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class ServicoService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  ServicoService(this._db, this._conn, this._ctx);

  Future<List<Servico>> listar(String barbeariaId, {bool somenteAtivos = true}) async {
    String where = 'barbearia_id = ?';
    List<Object?> args = [barbeariaId];

    if (somenteAtivos) {
      where += ' AND ativo = 1';
    }

    final rows = await _db.query('servicos', where: where, whereArgs: args, orderBy: 'nome ASC');
    return rows.map(Servico.fromMap).toList();
  }

  Future<Servico?> buscarPorId(int id) async {
    final rows = await _db.query('servicos', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Servico.fromMap(rows.first);
  }

  Future<Servico> salvar(Servico servico) async {
    _validate(servico);
    final data = servico.toMap()..remove('id');

    int id;
    if (servico.id == null) {
      id = await _db.insert('servicos', data);
    } else {
      await _db.update('servicos', data, servico.id!);
      id = servico.id!;
    }

    final saved = (await _db.query('servicos', where: 'id = ?', whereArgs: [id])).first;
    final result = Servico.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('servicos');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('servicos', {'firebase_id': fireId}, id);
        }
      }, context: 'ServicoService.salvar');
    }

    return result;
  }

  Future<void> desativar(int id) async {
    await _db.update('servicos', {'ativo': 0}, id);
  }

  Future<void> ativar(int id) async {
    await _db.update('servicos', {'ativo': 1}, id);
  }

  Future<void> popularDadosPadrao(String barbeariaId) async {
    final existing = await _db.query('servicos', where: 'barbearia_id = ?', whereArgs: [barbeariaId], limit: 1);
    if (existing.isNotEmpty) return;

    final servicos = [
      {'nome': 'Corte de Cabelo', 'preco': 35.0, 'duracao_minutos': 30},
      {'nome': 'Barba', 'preco': 25.0, 'duracao_minutos': 20},
      {'nome': 'Corte + Barba', 'preco': 55.0, 'duracao_minutos': 50},
      {'nome': 'Platinado', 'preco': 80.0, 'duracao_minutos': 90},
      {'nome': 'Hidratação', 'preco': 45.0, 'duracao_minutos': 40},
    ];

    for (final s in servicos) {
      await _db.insert('servicos', {
        'nome': s['nome'],
        'preco': s['preco'],
        'duracao_minutos': s['duracao_minutos'],
        'comissao_percentual': 50.0,
        'ativo': 1,
        'barbearia_id': barbeariaId,
      });
    }
  }

  void _validate(Servico s) {
    if (s.nome.trim().isEmpty) throw const ValidationException('Nome obrigatório.');
    if (s.preco <= 0) throw const ValidationException('Preço deve ser maior que zero.');
    if (s.duracaoMinutos <= 0) throw const ValidationException('Duração inválida.');
  }
}
