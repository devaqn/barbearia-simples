class Produto {
  final int? id;
  final String nome;
  final String? descricao;
  final double precoVenda;
  final double precoCusto;
  final double custoMedio;
  final int quantidade;
  final int estoqueMinimo;
  final double comissaoPercentual;
  final int? fornecedorId;
  final String barbeariaId;
  final String? firebaseId;

  const Produto({
    this.id,
    required this.nome,
    this.descricao,
    required this.precoVenda,
    this.precoCusto = 0.0,
    this.custoMedio = 0.0,
    this.quantidade = 0,
    this.estoqueMinimo = 5,
    this.comissaoPercentual = 0.0,
    this.fornecedorId,
    required this.barbeariaId,
    this.firebaseId,
  });

  bool get abaixoDoMinimo => quantidade <= estoqueMinimo;
  double get margem => precoVenda > 0 ? ((precoVenda - custoMedio) / precoVenda) * 100 : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'preco_venda': precoVenda,
        'preco_custo': precoCusto,
        'custo_medio': custoMedio,
        'quantidade': quantidade,
        'estoque_minimo': estoqueMinimo,
        'comissao_percentual': comissaoPercentual,
        'fornecedor_id': fornecedorId,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Produto.fromMap(Map<String, dynamic> m) => Produto(
        id: m['id'] as int?,
        nome: m['nome'] as String,
        descricao: m['descricao'] as String?,
        precoVenda: (m['preco_venda'] as num).toDouble(),
        precoCusto: (m['preco_custo'] as num?)?.toDouble() ?? 0.0,
        custoMedio: (m['custo_medio'] as num?)?.toDouble() ?? 0.0,
        quantidade: (m['quantidade'] as int?) ?? 0,
        estoqueMinimo: (m['estoque_minimo'] as int?) ?? 5,
        comissaoPercentual: (m['comissao_percentual'] as num?)?.toDouble() ?? 0.0,
        fornecedorId: m['fornecedor_id'] as int?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Produto copyWith({
    int? id,
    String? nome,
    String? descricao,
    double? precoVenda,
    double? precoCusto,
    double? custoMedio,
    int? quantidade,
    int? estoqueMinimo,
    double? comissaoPercentual,
    int? fornecedorId,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Produto(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        descricao: descricao ?? this.descricao,
        precoVenda: precoVenda ?? this.precoVenda,
        precoCusto: precoCusto ?? this.precoCusto,
        custoMedio: custoMedio ?? this.custoMedio,
        quantidade: quantidade ?? this.quantidade,
        estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
        comissaoPercentual: comissaoPercentual ?? this.comissaoPercentual,
        fornecedorId: fornecedorId ?? this.fornecedorId,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
