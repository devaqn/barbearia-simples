class Servico {
  final int? id;
  final String nome;
  final String? descricao;
  final double preco;
  final int duracaoMinutos;
  final double comissaoPercentual;
  final bool ativo;
  final String barbeariaId;
  final String? firebaseId;

  const Servico({
    this.id,
    required this.nome,
    this.descricao,
    required this.preco,
    this.duracaoMinutos = 30,
    this.comissaoPercentual = 50.0,
    this.ativo = true,
    required this.barbeariaId,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'duracao_minutos': duracaoMinutos,
        'comissao_percentual': comissaoPercentual,
        'ativo': ativo ? 1 : 0,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Servico.fromMap(Map<String, dynamic> m) => Servico(
        id: m['id'] as int?,
        nome: m['nome'] as String,
        descricao: m['descricao'] as String?,
        preco: (m['preco'] as num).toDouble(),
        duracaoMinutos: (m['duracao_minutos'] as int?) ?? 30,
        comissaoPercentual: (m['comissao_percentual'] as num?)?.toDouble() ?? 50.0,
        ativo: (m['ativo'] as int?) == 1,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Servico copyWith({
    int? id,
    String? nome,
    String? descricao,
    double? preco,
    int? duracaoMinutos,
    double? comissaoPercentual,
    bool? ativo,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Servico(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        descricao: descricao ?? this.descricao,
        preco: preco ?? this.preco,
        duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
        comissaoPercentual: comissaoPercentual ?? this.comissaoPercentual,
        ativo: ativo ?? this.ativo,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
