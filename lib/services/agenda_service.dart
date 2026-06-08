import '../database/database_helper.dart';
import '../models/agendamento.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';
import 'service_exceptions.dart';

class AgendaService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  AgendaService(this._db, this._conn, this._ctx);

  Future<List<Agendamento>> listarDia(
    String barbeariaId,
    DateTime dia, {
    int? barbeiroId,
  }) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = inicio.add(const Duration(days: 1));

    final conditions = [
      'barbearia_id = ?',
      'data_hora_inicio >= ?',
      'data_hora_inicio < ?',
    ];
    final args = <Object?>[
      barbeariaId,
      inicio.toIso8601String(),
      fim.toIso8601String(),
    ];

    if (barbeiroId != null) {
      conditions.add('barbeiro_id = ?');
      args.add(barbeiroId);
    }

    final rows = await _db.query(
      'agendamentos',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'data_hora_inicio ASC',
    );
    return rows.map(Agendamento.fromMap).toList();
  }

  Future<List<Agendamento>> listarMes(String barbeariaId, DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fim = DateTime(mes.year, mes.month + 1, 1);

    final rows = await _db.query(
      'agendamentos',
      where: 'barbearia_id = ? AND data_hora_inicio >= ? AND data_hora_inicio < ?',
      whereArgs: [barbeariaId, inicio.toIso8601String(), fim.toIso8601String()],
      orderBy: 'data_hora_inicio ASC',
    );
    return rows.map(Agendamento.fromMap).toList();
  }

  Future<bool> verificarConflito({
    required int barbeiroId,
    required DateTime inicio,
    required DateTime fim,
    int? excluirId,
  }) async {
    String where = '''
      barbeiro_id = ?
      AND status NOT IN ('cancelado')
      AND data_hora_inicio < ?
      AND data_hora_fim > ?
    ''';
    final args = <Object?>[barbeiroId, fim.toIso8601String(), inicio.toIso8601String()];

    if (excluirId != null) {
      where += ' AND id != ?';
      args.add(excluirId);
    }

    final rows = await _db.query('agendamentos', where: where, whereArgs: args, limit: 1);
    return rows.isNotEmpty;
  }

  Future<Agendamento> salvar(Agendamento ag) async {
    if (ag.dataHoraInicio.isAfter(ag.dataHoraFim)) {
      throw const ValidationException('Horário de início deve ser antes do fim.');
    }

    final conflito = await verificarConflito(
      barbeiroId: ag.barbeiroId,
      inicio: ag.dataHoraInicio,
      fim: ag.dataHoraFim,
      excluirId: ag.id,
    );
    if (conflito) {
      throw const ConflictException('Conflito de horário para este barbeiro.');
    }

    final data = ag.toMap()..remove('id');
    int id;
    if (ag.id == null) {
      id = await _db.insert('agendamentos', data);
    } else {
      await _db.update('agendamentos', data, ag.id!);
      id = ag.id!;
    }

    final saved = (await _db.query('agendamentos', where: 'id = ?', whereArgs: [id])).first;
    final result = Agendamento.fromMap(saved);

    if (_conn.isOnline) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final col = await _ctx.col('agendamentos');
        final fireId = result.firebaseId ?? col.doc().id;
        await col.doc(fireId).set({...result.toMap(), 'firebase_id': fireId});
        if (result.firebaseId == null) {
          await _db.update('agendamentos', {'firebase_id': fireId}, id);
        }
      }, context: 'AgendaService.salvar');
    }

    return result;
  }

  Future<Agendamento> atualizarStatus(int id, String status) async {
    await _db.update('agendamentos', {'status': status}, id);
    final rows = await _db.query('agendamentos', where: 'id = ?', whereArgs: [id]);
    return Agendamento.fromMap(rows.first);
  }
}
