class Caixa {
  final int? id;
  final int barbeiroId;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final double saldoInicial;
  final double? saldoFinal;
  final Map<String, double> resumoPagamentos;
  final String status; // 'aberto' | 'fechado'
  final String barbeariaId;
  final String? firebaseId;

  const Caixa({
    this.id,
    required this.barbeiroId,
    required this.dataAbertura,
    this.dataFechamento,
    this.saldoInicial = 0.0,
    this.saldoFinal,
    this.resumoPagamentos = const {},
    this.status = 'aberto',
    required this.barbeariaId,
    this.firebaseId,
  });

  bool get isAberto => status == 'aberto';

  Map<String, dynamic> toMap() => {
        'id': id,
        'barbeiro_id': barbeiroId,
        'data_abertura': dataAbertura.toIso8601String(),
        'data_fechamento': dataFechamento?.toIso8601String(),
        'saldo_inicial': saldoInicial,
        'saldo_final': saldoFinal,
        'resumo_pagamentos_json': _encodeResumo(resumoPagamentos),
        'status': status,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  static String encodeResumoStatic(Map<String, double> m) => _encodeResumo(m);

  static String _encodeResumo(Map<String, double> m) {
    final entries = m.entries.map((e) => '"${e.key}":${e.value}').join(',');
    return '{$entries}';
  }

  static Map<String, double> _decodeResumo(String? json) {
    if (json == null || json.isEmpty || json == '{}') return {};
    try {
      final cleaned = json.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
      return Map.fromEntries(
        cleaned.split(',').where((e) => e.contains(':')).map((e) {
          final parts = e.split(':');
          return MapEntry(parts[0].trim(), double.tryParse(parts[1].trim()) ?? 0.0);
        }),
      );
    } catch (_) {
      return {};
    }
  }

  factory Caixa.fromMap(Map<String, dynamic> m) => Caixa(
        id: m['id'] as int?,
        barbeiroId: m['barbeiro_id'] as int,
        dataAbertura: DateTime.parse(m['data_abertura'] as String),
        dataFechamento: m['data_fechamento'] != null
            ? DateTime.tryParse(m['data_fechamento'] as String)
            : null,
        saldoInicial: (m['saldo_inicial'] as num?)?.toDouble() ?? 0.0,
        saldoFinal: (m['saldo_final'] as num?)?.toDouble(),
        resumoPagamentos: _decodeResumo(m['resumo_pagamentos_json'] as String?),
        status: m['status'] as String,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Caixa copyWith({
    int? id,
    int? barbeiroId,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    double? saldoInicial,
    double? saldoFinal,
    Map<String, double>? resumoPagamentos,
    String? status,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Caixa(
        id: id ?? this.id,
        barbeiroId: barbeiroId ?? this.barbeiroId,
        dataAbertura: dataAbertura ?? this.dataAbertura,
        dataFechamento: dataFechamento ?? this.dataFechamento,
        saldoInicial: saldoInicial ?? this.saldoInicial,
        saldoFinal: saldoFinal ?? this.saldoFinal,
        resumoPagamentos: resumoPagamentos ?? this.resumoPagamentos,
        status: status ?? this.status,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
