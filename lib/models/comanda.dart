import 'item_comanda.dart';

class Comanda {
  final int? id;
  final int? clienteId;
  final int barbeiroId;
  final String status; // 'aberta' | 'fechada' | 'cancelada'
  final String? formaPagamento;
  final double totalServicos;
  final double totalProdutos;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String? observacoes;
  final String barbeariaId;
  final String? firebaseId;
  final List<ItemComanda> itens;

  const Comanda({
    this.id,
    this.clienteId,
    required this.barbeiroId,
    this.status = 'aberta',
    this.formaPagamento,
    this.totalServicos = 0.0,
    this.totalProdutos = 0.0,
    required this.dataAbertura,
    this.dataFechamento,
    this.observacoes,
    required this.barbeariaId,
    this.firebaseId,
    this.itens = const [],
  });

  double get total => totalServicos + totalProdutos;
  bool get isAberta => status == 'aberta';
  bool get isFechada => status == 'fechada';

  Map<String, dynamic> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'barbeiro_id': barbeiroId,
        'status': status,
        'forma_pagamento': formaPagamento,
        'total_servicos': totalServicos,
        'total_produtos': totalProdutos,
        'total': total,
        'data_abertura': dataAbertura.toIso8601String(),
        'data_fechamento': dataFechamento?.toIso8601String(),
        'observacoes': observacoes,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Comanda.fromMap(Map<String, dynamic> m, {List<ItemComanda> itens = const []}) =>
      Comanda(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int?,
        barbeiroId: m['barbeiro_id'] as int,
        status: m['status'] as String,
        formaPagamento: m['forma_pagamento'] as String?,
        totalServicos: (m['total_servicos'] as num?)?.toDouble() ?? 0.0,
        totalProdutos: (m['total_produtos'] as num?)?.toDouble() ?? 0.0,
        dataAbertura: DateTime.parse(m['data_abertura'] as String),
        dataFechamento: m['data_fechamento'] != null
            ? DateTime.tryParse(m['data_fechamento'] as String)
            : null,
        observacoes: m['observacoes'] as String?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
        itens: itens,
      );

  Comanda copyWith({
    int? id,
    int? clienteId,
    int? barbeiroId,
    String? status,
    String? formaPagamento,
    double? totalServicos,
    double? totalProdutos,
    DateTime? dataAbertura,
    DateTime? dataFechamento,
    String? observacoes,
    String? barbeariaId,
    String? firebaseId,
    List<ItemComanda>? itens,
  }) =>
      Comanda(
        id: id ?? this.id,
        clienteId: clienteId ?? this.clienteId,
        barbeiroId: barbeiroId ?? this.barbeiroId,
        status: status ?? this.status,
        formaPagamento: formaPagamento ?? this.formaPagamento,
        totalServicos: totalServicos ?? this.totalServicos,
        totalProdutos: totalProdutos ?? this.totalProdutos,
        dataAbertura: dataAbertura ?? this.dataAbertura,
        dataFechamento: dataFechamento ?? this.dataFechamento,
        observacoes: observacoes ?? this.observacoes,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
        itens: itens ?? this.itens,
      );
}
