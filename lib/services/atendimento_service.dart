import '../database/database_helper.dart';
import '../models/atendimento.dart';

class AtendimentoService {
  final DatabaseHelper _db;

  AtendimentoService(this._db);

  Future<List<Atendimento>> listar({
    required String barbeariaId,
    int? barbeiroId,
    int? clienteId,
    DateTime? inicio,
    DateTime? fim,
    int limit = 50,
  }) async {
    final conditions = ['a.barbearia_id = ?'];
    final args = <Object?>[barbeariaId];

    if (barbeiroId != null) { conditions.add('a.barbeiro_id = ?'); args.add(barbeiroId); }
    if (clienteId != null) { conditions.add('a.cliente_id = ?'); args.add(clienteId); }
    if (inicio != null) { conditions.add('a.data_hora >= ?'); args.add(inicio.toIso8601String()); }
    if (fim != null) { conditions.add('a.data_hora <= ?'); args.add(fim.toIso8601String()); }

    final rows = await _db.rawQuery(
      'SELECT * FROM atendimentos a WHERE ${conditions.join(' AND ')} ORDER BY a.data_hora DESC LIMIT ?',
      [...args, limit],
    );

    return Future.wait(rows.map((r) async {
      final id = r['id'] as int;
      final itensRows = await _db.query('atendimento_itens', where: 'atendimento_id = ?', whereArgs: [id]);
      return Atendimento.fromMap(r, itens: itensRows.map(AtendimentoItem.fromMap).toList());
    }));
  }

  Future<Atendimento> criarDeComanda(int comandaId, String barbeariaId) async {
    final comandaRows = await _db.query('comandas', where: 'id = ?', whereArgs: [comandaId]);
    if (comandaRows.isEmpty) throw StateError('Comanda $comandaId não encontrada.');
    final comanda = comandaRows.first;

    final atId = await _db.transaction((txn) async {
      final atendimentoId = await txn.insert('atendimentos', {
        'cliente_id': comanda['cliente_id'],
        'barbeiro_id': comanda['barbeiro_id'],
        'data_hora': (comanda['data_fechamento'] ?? DateTime.now().toIso8601String()),
        'total': comanda['total'],
        'forma_pagamento': comanda['forma_pagamento'],
        'observacoes': comanda['observacoes'],
        'barbearia_id': barbeariaId,
      });

      final itens = await txn.query('comandas_itens', where: 'comanda_id = ?', whereArgs: [comandaId]);
      for (final item in itens) {
        await txn.insert('atendimento_itens', {
          'atendimento_id': atendimentoId,
          'tipo': item['tipo'],
          'referencia_id': item['referencia_id'],
          'descricao': item['descricao'],
          'preco_unitario': item['preco_unitario'],
          'quantidade': item['quantidade'],
          'subtotal': item['subtotal'],
          'comissao_valor': item['comissao_valor'],
        });
      }

      return atendimentoId;
    });

    final rows = await _db.query('atendimentos', where: 'id = ?', whereArgs: [atId]);
    final itensRows = await _db.query('atendimento_itens', where: 'atendimento_id = ?', whereArgs: [atId]);
    return Atendimento.fromMap(rows.first, itens: itensRows.map(AtendimentoItem.fromMap).toList());
  }
}
