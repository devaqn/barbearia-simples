class MovimentoEstoque {
  final int? id;
  final int produtoId;
  final String tipo; // 'entrada' | 'saida'
  final int quantidade;
  final double custoUnitario;
  final String? observacoes;
  final DateTime dataHora;
  final String barbeariaId;
  final String? firebaseId;

  const MovimentoEstoque({
    this.id,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    this.custoUnitario = 0.0,
    this.observacoes,
    required this.dataHora,
    required this.barbeariaId,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'produto_id': produtoId,
        'tipo': tipo,
        'quantidade': quantidade,
        'custo_unitario': custoUnitario,
        'observacoes': observacoes,
        'data_hora': dataHora.toIso8601String(),
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory MovimentoEstoque.fromMap(Map<String, dynamic> m) => MovimentoEstoque(
        id: m['id'] as int?,
        produtoId: m['produto_id'] as int,
        tipo: m['tipo'] as String,
        quantidade: m['quantidade'] as int,
        custoUnitario: (m['custo_unitario'] as num?)?.toDouble() ?? 0.0,
        observacoes: m['observacoes'] as String?,
        dataHora: DateTime.parse(m['data_hora'] as String),
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );
}
