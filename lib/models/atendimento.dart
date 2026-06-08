class AtendimentoItem {
  final int? id;
  final int atendimentoId;
  final String tipo; // 'servico' | 'produto'
  final int referenciaId;
  final String descricao;
  final double precoUnitario;
  final int quantidade;
  final double subtotal;
  final double comissaoValor;

  const AtendimentoItem({
    this.id,
    required this.atendimentoId,
    required this.tipo,
    required this.referenciaId,
    required this.descricao,
    required this.precoUnitario,
    this.quantidade = 1,
    required this.subtotal,
    this.comissaoValor = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'atendimento_id': atendimentoId,
        'tipo': tipo,
        'referencia_id': referenciaId,
        'descricao': descricao,
        'preco_unitario': precoUnitario,
        'quantidade': quantidade,
        'subtotal': subtotal,
        'comissao_valor': comissaoValor,
      };

  factory AtendimentoItem.fromMap(Map<String, dynamic> m) => AtendimentoItem(
        id: m['id'] as int?,
        atendimentoId: m['atendimento_id'] as int,
        tipo: m['tipo'] as String,
        referenciaId: m['referencia_id'] as int,
        descricao: m['descricao'] as String,
        precoUnitario: (m['preco_unitario'] as num).toDouble(),
        quantidade: (m['quantidade'] as int?) ?? 1,
        subtotal: (m['subtotal'] as num).toDouble(),
        comissaoValor: (m['comissao_valor'] as num?)?.toDouble() ?? 0.0,
      );
}

class Atendimento {
  final int? id;
  final int? clienteId;
  final int barbeiroId;
  final DateTime dataHora;
  final double total;
  final String formaPagamento;
  final String? observacoes;
  final String barbeariaId;
  final String? firebaseId;
  final List<AtendimentoItem> itens;

  const Atendimento({
    this.id,
    this.clienteId,
    required this.barbeiroId,
    required this.dataHora,
    required this.total,
    required this.formaPagamento,
    this.observacoes,
    required this.barbeariaId,
    this.firebaseId,
    this.itens = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'barbeiro_id': barbeiroId,
        'data_hora': dataHora.toIso8601String(),
        'total': total,
        'forma_pagamento': formaPagamento,
        'observacoes': observacoes,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Atendimento.fromMap(Map<String, dynamic> m, {List<AtendimentoItem> itens = const []}) =>
      Atendimento(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int?,
        barbeiroId: m['barbeiro_id'] as int,
        dataHora: DateTime.parse(m['data_hora'] as String),
        total: (m['total'] as num).toDouble(),
        formaPagamento: m['forma_pagamento'] as String,
        observacoes: m['observacoes'] as String?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
        itens: itens,
      );
}
