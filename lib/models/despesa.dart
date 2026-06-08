class Despesa {
  final int? id;
  final String descricao;
  final String categoria;
  final double valor;
  final DateTime data;
  final String? observacoes;
  final String barbeariaId;
  final String? firebaseId;

  const Despesa({
    this.id,
    required this.descricao,
    required this.categoria,
    required this.valor,
    required this.data,
    this.observacoes,
    required this.barbeariaId,
    this.firebaseId,
  });

  static const List<String> categorias = [
    'Aluguel',
    'Energia',
    'Água',
    'Internet',
    'Produtos',
    'Equipamentos',
    'Marketing',
    'Salários',
    'Outros',
  ];

  Map<String, dynamic> toMap() => {
        'id': id,
        'descricao': descricao,
        'categoria': categoria,
        'valor': valor,
        'data': data.toIso8601String(),
        'observacoes': observacoes,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Despesa.fromMap(Map<String, dynamic> m) => Despesa(
        id: m['id'] as int?,
        descricao: m['descricao'] as String,
        categoria: m['categoria'] as String,
        valor: (m['valor'] as num).toDouble(),
        data: DateTime.parse(m['data'] as String),
        observacoes: m['observacoes'] as String?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Despesa copyWith({
    int? id,
    String? descricao,
    String? categoria,
    double? valor,
    DateTime? data,
    String? observacoes,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Despesa(
        id: id ?? this.id,
        descricao: descricao ?? this.descricao,
        categoria: categoria ?? this.categoria,
        valor: valor ?? this.valor,
        data: data ?? this.data,
        observacoes: observacoes ?? this.observacoes,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
