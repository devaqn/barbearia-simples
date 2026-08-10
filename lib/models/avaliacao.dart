class Avaliacao {
  final int? id;
  final int clienteId;
  final int barbeiroId;
  final int? agendamentoId;
  final int nota; // 1-5 stars
  final String? comentario;
  final String barbeariaId;
  final String? firebaseId;
  final DateTime? criadoEm;

  const Avaliacao({
    this.id,
    required this.clienteId,
    required this.barbeiroId,
    this.agendamentoId,
    required this.nota,
    this.comentario,
    required this.barbeariaId,
    this.firebaseId,
    this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'barbeiro_id': barbeiroId,
        'agendamento_id': agendamentoId,
        'nota': nota,
        'comentario': comentario,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
        'criado_em': criadoEm?.toIso8601String(),
      };

  factory Avaliacao.fromMap(Map<String, dynamic> m) => Avaliacao(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int,
        barbeiroId: m['barbeiro_id'] as int,
        agendamentoId: m['agendamento_id'] as int?,
        nota: m['nota'] as int,
        comentario: m['comentario'] as String?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
        criadoEm: m['criado_em'] != null
            ? DateTime.tryParse(m['criado_em'] as String)
            : null,
      );

  Avaliacao copyWith({
    int? id,
    int? clienteId,
    int? barbeiroId,
    int? agendamentoId,
    int? nota,
    String? comentario,
    String? barbeariaId,
    String? firebaseId,
    DateTime? criadoEm,
  }) =>
      Avaliacao(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        barbeiroId: barbeiroId ?? this.barbeiroId,
        agendamentoId: agendamentoId ?? this.agendamentoId,
        nota: nota ?? this.nota,
        comentario: comentario ?? this.comentario,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
        criadoEm: criadoEm ?? this.criadoEm,
      );
}
