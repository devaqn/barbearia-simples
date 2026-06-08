class Assinatura {
  final int? id;
  final int clienteId;
  final String plano;
  final String status;
  final double valor;
  final DateTime dataInicio;
  final DateTime dataVencimento;
  final String? mpSubscriptionId;
  final String? mpPayerId;
  final String barbeariaId;
  final String? firebaseId;

  const Assinatura({
    this.id,
    required this.clienteId,
    required this.plano,
    required this.status,
    required this.valor,
    required this.dataInicio,
    required this.dataVencimento,
    this.mpSubscriptionId,
    this.mpPayerId,
    required this.barbeariaId,
    this.firebaseId,
  });

  bool get estaEmDia {
    if (status != 'ativo') return false;
    return dataVencimento.isAfter(DateTime.now());
  }

  int get diasParaVencer => dataVencimento.difference(DateTime.now()).inDays;

  bool get venceEm7Dias => diasParaVencer >= 0 && diasParaVencer <= 7;

  Map<String, dynamic> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'plano': plano,
        'status': status,
        'valor': valor,
        'data_inicio': dataInicio.toIso8601String(),
        'data_vencimento': dataVencimento.toIso8601String(),
        'mp_subscription_id': mpSubscriptionId,
        'mp_payer_id': mpPayerId,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Assinatura.fromMap(Map<String, dynamic> m) => Assinatura(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int,
        plano: m['plano'] as String,
        status: m['status'] as String,
        valor: (m['valor'] as num).toDouble(),
        dataInicio: DateTime.parse(m['data_inicio'] as String),
        dataVencimento: DateTime.parse(m['data_vencimento'] as String),
        mpSubscriptionId: m['mp_subscription_id'] as String?,
        mpPayerId: m['mp_payer_id'] as String?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Assinatura copyWith({
    int? id,
    int? clienteId,
    String? plano,
    String? status,
    double? valor,
    DateTime? dataInicio,
    DateTime? dataVencimento,
    String? mpSubscriptionId,
    String? mpPayerId,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Assinatura(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        plano: plano ?? this.plano,
        status: status ?? this.status,
        valor: valor ?? this.valor,
        dataInicio: dataInicio ?? this.dataInicio,
        dataVencimento: dataVencimento ?? this.dataVencimento,
        mpSubscriptionId: mpSubscriptionId ?? this.mpSubscriptionId,
        mpPayerId: mpPayerId ?? this.mpPayerId,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
