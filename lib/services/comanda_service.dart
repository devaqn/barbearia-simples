import '../database/database_helper.dart';
import '../models/comanda.dart';
import '../models/item_comanda.dart';
import 'cliente_service.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class ComandaService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;
  // ignore: unused_field
  final ClienteService _clienteSvc;

  ComandaService(this._db, this._conn, this._ctx, this._clienteSvc);

  Future<Comanda> abrir({
    required int barbeiroId,
    required String barbeariaId,
    int? clienteId,
    String? observacoes,
  }) async {
    final now = DateTime.now();
    final id = await _db.insert('comandas', {
      'cliente_id': clienteId,
      'barbeiro_id': barbeiroId,
      'status': 'aberta',
      'total_servicos': 0.0,
      'total_produtos': 0.0,
      'total': 0.0,
      'data_abertura': now.toIso8601String(),
      'observacoes': observacoes,
      'barbearia_id': barbeariaId,
    });

    return _carregar(id);
  }

  Future<Comanda> _carregar(int id) async {
    final rows = await _db.query('comandas', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw const NotFoundException('Comanda não encontrada.');
    final itensRows = await _db.query('comandas_itens', where: 'comanda_id = ?', whereArgs: [id]);
    return Comanda.fromMap(rows.first, itens: itensRows.map(ItemComanda.fromMap).toList());
  }

  Future<List<Comanda>> listar({
    required String barbeariaId,
    int? barbeiroId,
    String? status,
  }) async {
    final conditions = ['barbearia_id = ?'];
    final args = <Object?>[barbeariaId];

    if (barbeiroId != null) {
      conditions.add('barbeiro_id = ?');
      args.add(barbeiroId);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }

    final rows = await _db.query(
      'comandas',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'data_abertura DESC',
    );

    return Future.wait(rows.map((r) async {
      final id = r['id'] as int;
      final itensRows = await _db.query('comandas_itens', where: 'comanda_id = ?', whereArgs: [id]);
      return Comanda.fromMap(r, itens: itensRows.map(ItemComanda.fromMap).toList());
    }));
  }

  Future<Comanda> adicionarItem(int comandaId, ItemComanda item) async {
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'comandas',
        where: "id = ? AND status = 'aberta'",
        whereArgs: [comandaId],
      );
      if (rows.isEmpty) throw const ConflictException('Comanda não está aberta.');

      await txn.insert('comandas_itens', item.toMap()..remove('id'));
      await _recalcularTotais(txn, comandaId);
    });

    return _carregar(comandaId);
  }

  Future<Comanda> removerItem(int itemId, int comandaId) async {
    await _db.transaction((txn) async {
      await txn.delete('comandas_itens', where: 'id = ?', whereArgs: [itemId]);
      await _recalcularTotais(txn, comandaId);
    });

    return _carregar(comandaId);
  }

  Future<Comanda> fechar({
    required int comandaId,
    required String formaPagamento,
  }) async {
    final now = DateTime.now();

    await _db.transaction((txn) async {
      // Optimistic lock: only close if still aberta
      final rows = await txn.query(
        'comandas',
        where: "id = ? AND status = 'aberta'",
        whereArgs: [comandaId],
      );
      if (rows.isEmpty) throw const ConflictException('Comanda já foi fechada ou cancelada.');

      final comanda = Comanda.fromMap(rows.first);

      await txn.update(
        'comandas',
        {
          'status': 'fechada',
          'forma_pagamento': formaPagamento,
          'data_fechamento': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [comandaId],
      );

      // Baixa de estoque para produtos
      final itens = await txn.query('comandas_itens', where: 'comanda_id = ?', whereArgs: [comandaId]);
      for (final itemRow in itens) {
        if (itemRow['tipo'] == 'produto') {
          final prodId = itemRow['referencia_id'] as int;
          final qty = itemRow['quantidade'] as int;
          final prodRows = await txn.query('produtos', where: 'id = ?', whereArgs: [prodId]);
          if (prodRows.isNotEmpty) {
            final atual = prodRows.first['quantidade'] as int;
            await txn.update(
              'produtos',
              {'quantidade': atual - qty},
              where: 'id = ?',
              whereArgs: [prodId],
            );
          }
        }
      }

      // Registrar comissão
      final comissaoTotal = itens.fold<double>(
        0.0,
        (acc, i) => acc + ((i['comissao_valor'] as num?)?.toDouble() ?? 0.0),
      );
      if (comissaoTotal > 0) {
        await txn.insert('comissoes', {
          'barbeiro_id': comanda.barbeiroId,
          'comanda_id': comandaId,
          'valor': comissaoTotal,
          'data': now.toIso8601String(),
          'pago': 0,
          'barbearia_id': comanda.barbeariaId,
        });
      }

      // Atualizar fidelidade do cliente
      if (comanda.clienteId != null) {
        await txn.rawUpdate('''
          UPDATE clientes
          SET total_atendimentos = total_atendimentos + 1,
              total_gasto = total_gasto + ?,
              pontos_fidelidade = pontos_fidelidade + ?,
              atualizado_em = datetime('now')
          WHERE id = ?
        ''', [comanda.total, comanda.total.toInt(), comanda.clienteId]);
      }
    });

    final result = await _carregar(comandaId);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('comandas');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
      }, context: 'ComandaService.fechar');
    }

    return result;
  }

  Future<void> cancelar(int comandaId) async {
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'comandas',
        where: "id = ? AND status = 'aberta'",
        whereArgs: [comandaId],
      );
      if (rows.isEmpty) throw const ConflictException('Comanda não pode ser cancelada.');

      await txn.update(
        'comandas',
        {'status': 'cancelada', 'data_fechamento': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [comandaId],
      );
    });
  }

  Future<void> _recalcularTotais(dynamic txn, int comandaId) async {
    final itens = await txn.query('comandas_itens', where: 'comanda_id = ?', whereArgs: [comandaId]) as List<Map<String, dynamic>>;
    double totalSvc = 0, totalProd = 0;
    for (final i in itens) {
      final sub = (i['subtotal'] as num?)?.toDouble() ?? 0.0;
      if (i['tipo'] == 'servico') {
        totalSvc += sub;
      } else {
        totalProd += sub;
      }
    }
    await txn.update(
      'comandas',
      {
        'total_servicos': totalSvc,
        'total_produtos': totalProd,
        'total': totalSvc + totalProd,
      },
      where: 'id = ?',
      whereArgs: [comandaId],
    );
  }
}
