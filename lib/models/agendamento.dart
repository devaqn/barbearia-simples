class Agendamento {
  final int? id;
  final int clienteId;
  final int barbeiroId;
  final int? servicoId;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final String status; // 'pendente' | 'confirmado' | 'cancelado' | 'concluido'
  final String? observacoes;
  final bool faturado;
  final String barbeariaId;
  final String? firebaseId;

  const Agendamento({
    this.id,
    required this.clienteId,
    required this.barbeiroId,
    this.servicoId,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    this.status = 'pendente',
    this.observacoes,
    this.faturado = false,
    required this.barbeariaId,
    this.firebaseId,
  });

  bool get isPendente => status == 'pendente';
  bool get isConfirmado => status == 'confirmado';
  bool get isCancelado => status == 'cancelado';
  bool get isConcluido => status == 'concluido';

  Map<String, dynamic> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'barbeiro_id': barbeiroId,
        'servico_id': servicoId,
        'data_hora_inicio': dataHoraInicio.toIso8601String(),
        'data_hora_fim': dataHoraFim.toIso8601String(),
        'status': status,
        'observacoes': observacoes,
        'faturado': faturado ? 1 : 0,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Agendamento.fromMap(Map<String, dynamic> m) => Agendamento(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int,
        barbeiroId: m['barbeiro_id'] as int,
        servicoId: m['servico_id'] as int?,
        dataHoraInicio: DateTime.parse(m['data_hora_inicio'] as String),
        dataHoraFim: DateTime.parse(m['data_hora_fim'] as String),
        status: m['status'] as String,
        observacoes: m['observacoes'] as String?,
        faturado: (m['faturado'] as int?) == 1,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Agendamento copyWith({
    int? id,
    int? clienteId,
    int? barbeiroId,
    int? servicoId,
    DateTime? dataHoraInicio,
    DateTime? dataHoraFim,
    String? status,
    String? observacoes,
    bool? faturado,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Agendamento(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        barbeiroId: barbeiroId ?? this.barbeiroId,
        servicoId: servicoId ?? this.servicoId,
        dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
        dataHoraFim: dataHoraFim ?? this.dataHoraFim,
        status: status ?? this.status,
        observacoes: observacoes ?? this.observacoes,
        faturado: faturado ?? this.faturado,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
