import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Public booking service that reads/writes directly to Firestore.
/// No auth required — designed for client-facing booking flow.
class BookingService {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(
    String barbeariaId,
    String name,
  ) {
    return _firestore
        .collection(AppConstants.colBarbearias)
        .doc(barbeariaId)
        .collection(name);
  }

  /// Fetches the barbershop name from the root document.
  Future<String> getBarbeariaName(String barbeariaId) async {
    final doc = await _firestore
        .collection(AppConstants.colBarbearias)
        .doc(barbeariaId)
        .get();
    if (!doc.exists) throw Exception('Barbearia nao encontrada');
    final data = doc.data()!;
    return (data['nome'] as String?) ?? 'Barbearia';
  }

  /// Lists active services for the barbershop.
  Future<List<Map<String, dynamic>>> getServicos(String barbeariaId) async {
    final snap = await _col(barbeariaId, AppConstants.colServicos)
        .where('ativo', isEqualTo: 1)
        .get();
    return snap.docs.map((d) => {'firebase_id': d.id, ...d.data()}).toList();
  }

  /// Lists active barbers for the barbershop.
  Future<List<Map<String, dynamic>>> getBarbeiros(String barbeariaId) async {
    final snap = await _col(barbeariaId, AppConstants.colUsuarios)
        .where('ativo', isEqualTo: 1)
        .get();
    return snap.docs.map((d) => {'firebase_id': d.id, ...d.data()}).toList();
  }

  /// Gets existing appointments for a barber on a given date.
  Future<List<Map<String, dynamic>>> getAgendamentosDia(
    String barbeariaId,
    int barbeiroId,
    DateTime dia,
  ) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = inicio.add(const Duration(days: 1));

    final snap = await _col(barbeariaId, AppConstants.colAgendamentos)
        .where('barbeiro_id', isEqualTo: barbeiroId)
        .where('data_hora_inicio', isGreaterThanOrEqualTo: inicio.toIso8601String())
        .where('data_hora_inicio', isLessThan: fim.toIso8601String())
        .get();

    return snap.docs
        .map((d) => d.data())
        .where((a) => a['status'] != 'cancelado')
        .toList();
  }

  /// Generates available time slots for a barber on a given day.
  /// Default working hours: 08:00 - 20:00 with 30-min intervals.
  List<DateTime> getHorariosDisponiveis({
    required DateTime dia,
    required int duracaoMinutos,
    required List<Map<String, dynamic>> agendamentosExistentes,
    int horaInicio = 8,
    int horaFim = 20,
  }) {
    final slots = <DateTime>[];
    final now = DateTime.now();

    var slot = DateTime(dia.year, dia.month, dia.day, horaInicio);
    final limite = DateTime(dia.year, dia.month, dia.day, horaFim);

    while (slot.add(Duration(minutes: duracaoMinutos)).isBefore(limite) ||
        slot.add(Duration(minutes: duracaoMinutos)).isAtSameMomentAs(limite)) {
      final slotFim = slot.add(Duration(minutes: duracaoMinutos));

      // Skip past times
      if (slot.isBefore(now)) {
        slot = slot.add(const Duration(minutes: 30));
        continue;
      }

      // Check conflicts
      final hasConflict = agendamentosExistentes.any((ag) {
        final agInicio = DateTime.parse(ag['data_hora_inicio'] as String);
        final agFim = DateTime.parse(ag['data_hora_fim'] as String);
        return slot.isBefore(agFim) && slotFim.isAfter(agInicio);
      });

      if (!hasConflict) {
        slots.add(slot);
      }

      slot = slot.add(const Duration(minutes: 30));
    }

    return slots;
  }

  /// Finds or creates a client by phone number.
  Future<Map<String, dynamic>> findOrCreateCliente({
    required String barbeariaId,
    required String nome,
    required String telefone,
  }) async {
    final col = _col(barbeariaId, AppConstants.colClientes);

    // Try to find existing client by phone
    final existing = await col.where('telefone', isEqualTo: telefone).limit(1).get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      return {'firebase_id': doc.id, ...doc.data()};
    }

    // Create new client
    final now = DateTime.now().toIso8601String();
    final clienteData = {
      'nome': nome,
      'telefone': telefone,
      'total_atendimentos': 0,
      'total_gasto': 0.0,
      'pontos_fidelidade': 0,
      'is_assinante': 0,
      'barbearia_id': barbeariaId,
      'criado_em': now,
      'atualizado_em': now,
    };

    final docRef = await col.add(clienteData);
    await docRef.update({'firebase_id': docRef.id});
    return {'firebase_id': docRef.id, ...clienteData};
  }

  /// Creates a new appointment in Firestore.
  Future<String> criarAgendamento({
    required String barbeariaId,
    required int clienteId,
    required String clienteFirebaseId,
    required int barbeiroId,
    required int? servicoId,
    required String? servicoFirebaseId,
    required DateTime dataHoraInicio,
    required DateTime dataHoraFim,
    String? observacoes,
  }) async {
    final col = _col(barbeariaId, AppConstants.colAgendamentos);

    final agData = {
      'cliente_id': clienteId,
      'barbeiro_id': barbeiroId,
      'servico_id': servicoId,
      'data_hora_inicio': dataHoraInicio.toIso8601String(),
      'data_hora_fim': dataHoraFim.toIso8601String(),
      'status': 'pendente',
      'observacoes': observacoes ?? 'Agendamento online',
      'faturado': 0,
      'barbearia_id': barbeariaId,
      'origem': 'booking_online',
    };

    final docRef = await col.add(agData);
    await docRef.update({'firebase_id': docRef.id});
    return docRef.id;
  }
}
