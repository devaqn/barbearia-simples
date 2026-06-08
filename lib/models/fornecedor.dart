class Fornecedor {
  final int? id;
  final String nome;
  final String? telefone;
  final String? email;
  final String barbeariaId;
  final String? firebaseId;

  const Fornecedor({
    this.id,
    required this.nome,
    this.telefone,
    this.email,
    required this.barbeariaId,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'telefone': telefone,
        'email': email,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Fornecedor.fromMap(Map<String, dynamic> m) => Fornecedor(
        id: m['id'] as int?,
        nome: m['nome'] as String,
        telefone: m['telefone'] as String?,
        email: m['email'] as String?,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Fornecedor copyWith({
    int? id,
    String? nome,
    String? telefone,
    String? email,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Fornecedor(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        email: email ?? this.email,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
