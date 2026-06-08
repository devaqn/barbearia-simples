import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import 'connectivity_service.dart';
import 'firebase_context_service.dart';
import 'firebase_error_handler.dart';

class RealtimeSyncService {
  final DatabaseHelper _db;
  final ConnectivityService _conn;
  final FirebaseContextService _ctx;

  bool _listening = false;
  final List<StreamSubscription> _subs = [];

  RealtimeSyncService(this._db, this._conn, this._ctx);

  Future<void> startListening() async {
    if (_listening) return;
    _listening = true;

    try {
      await _listenCollection('clientes');
      await _listenCollection('servicos');
      await _listenCollection('produtos');
      await _listenCollection('comandas');
      await _listenCollection('agendamentos');
      await _listenCollection('usuarios');
    } catch (e) {
      _listening = false;
      if (kDebugMode) debugPrint('[RealtimeSync] startListening error: $e');
    }
  }

  Future<void> _listenCollection(String name) async {
    final col = await _ctx.col(name);
    final sub = col.snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          await FirebaseErrorHandler.wrapSilent(
            () => _applyChange(name, change),
            context: 'RealtimeSync.$name',
          );
        }
      },
      onError: (e) {
        if (kDebugMode) debugPrint('[RealtimeSync] $name error: $e');
      },
    );
    _subs.add(sub);
  }

  Future<void> _applyChange(
    String table,
    DocumentChange<Map<String, dynamic>> change,
  ) async {
    final data = change.doc.data();
    if (data == null) return;

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
        final existing = await _db.query(
          table,
          where: 'firebase_id = ?',
          whereArgs: [change.doc.id],
        );
        final row = {...data, 'firebase_id': change.doc.id};
        if (existing.isEmpty) {
          await _db.insert(table, row);
        } else {
          final localId = existing.first['id'] as int;
          await _db.update(table, row, localId);
        }
      case DocumentChangeType.removed:
        await _db.rawQuery(
          'DELETE FROM $table WHERE firebase_id = ?',
          [change.doc.id],
        );
    }
  }

  Future<void> syncPendingRecords(String barbeariaId) async {
    if (!_conn.isOnline) return;

    const tables = [
      'clientes', 'servicos', 'produtos', 'comandas',
      'agendamentos', 'despesas', 'assinaturas',
    ];

    for (final table in tables) {
      await FirebaseErrorHandler.wrapSilent(() async {
        final pending = await _db.query(
          table,
          where: 'firebase_id IS NULL AND barbearia_id = ?',
          whereArgs: [barbeariaId],
          limit: 20,
        );

        for (final row in pending) {
          final col = await _ctx.col(table);
          final fireId = col.doc().id;
          await col.doc(fireId).set({...row, 'firebase_id': fireId});
          final localId = row['id'] as int;
          await _db.update(table, {'firebase_id': fireId}, localId);
        }
      }, context: 'syncPending.$table');
    }
  }

  void stopListening() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _listening = false;
  }
}
