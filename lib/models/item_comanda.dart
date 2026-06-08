class ItemComanda {
  final int? id;
  final int comandaId;
  final String tipo; // 'servico' | 'produto'
  final int referenciaId;
  final String descricao;
  final double precoUnitario;
  final int quantidade;
  final double comissaoPercentual;

  const ItemComanda({
    this.id,
    required this.comandaId,
    required this.tipo,
    required this.referenciaId,
    required this.descricao,
    required this.precoUnitario,
    this.quantidade = 1,
    this.comissaoPercentual = 0.0,
  });

  double get subtotal => precoUnitario * quantidade;
  double get comissaoValor => subtotal * (comissaoPercentual / 100);
  double get lucroCasa => subtotal - comissaoValor;

  Map<String, dynamic> toMap() => {
        'id': id,
        'comanda_id': comandaId,
        'tipo': tipo,
        'referencia_id': referenciaId,
        'descricao': descricao,
        'preco_unitario': precoUnitario,
        'quantidade': quantidade,
        'subtotal': subtotal,
        'comissao_percentual': comissaoPercentual,
        'comissao_valor': comissaoValor,
      };

  factory ItemComanda.fromMap(Map<String, dynamic> m) => ItemComanda(
        id: m['id'] as int?,
        comandaId: m['comanda_id'] as int,
        tipo: m['tipo'] as String,
        referenciaId: m['referencia_id'] as int,
        descricao: m['descricao'] as String,
        precoUnitario: (m['preco_unitario'] as num).toDouble(),
        quantidade: (m['quantidade'] as int?) ?? 1,
        comissaoPercentual: (m['comissao_percentual'] as num?)?.toDouble() ?? 0.0,
      );

  ItemComanda copyWith({
    int? id,
    int? comandaId,
    String? tipo,
    int? referenciaId,
    String? descricao,
    double? precoUnitario,
    int? quantidade,
    double? comissaoPercentual,
  }) =>
      ItemComanda(
        id: id ?? this.id,
        comandaId: comandaId ?? this.comandaId,
        tipo: tipo ?? this.tipo,
        referenciaId: referenciaId ?? this.referenciaId,
        descricao: descricao ?? this.descricao,
        precoUnitario: precoUnitario ?? this.precoUnitario,
        quantidade: quantidade ?? this.quantidade,
        comissaoPercentual: comissaoPercentual ?? this.comissaoPercentual,
      );
}
