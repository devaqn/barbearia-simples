enum UserRole { admin, barbeiro }

class Usuario {
  final int? id;
  final String? firebaseUid;
  final String nome;
  final String email;
  final UserRole role;
  final double comissaoPercentual;
  final String? fotoUrl;
  final bool ativo;
  final bool revoked;
  final String barbeariaId;
  final String? firebaseId;

  const Usuario({
    this.id,
    this.firebaseUid,
    required this.nome,
    required this.email,
    required this.role,
    this.comissaoPercentual = 50.0,
    this.fotoUrl,
    this.ativo = true,
    this.revoked = false,
    required this.barbeariaId,
    this.firebaseId,
  });

  bool get isAdmin => role == UserRole.admin;
  double get comissaoDecimal => comissaoPercentual / 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'firebase_uid': firebaseUid,
        'nome': nome,
        'email': email,
        'role': role.name,
        'comissao_percentual': comissaoPercentual,
        'foto_url': fotoUrl,
        'ativo': ativo ? 1 : 0,
        'revoked': revoked ? 1 : 0,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
      };

  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
        id: m['id'] as int?,
        firebaseUid: m['firebase_uid'] as String?,
        nome: m['nome'] as String,
        email: m['email'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == m['role'],
          orElse: () => UserRole.barbeiro,
        ),
        comissaoPercentual: (m['comissao_percentual'] as num?)?.toDouble() ?? 50.0,
        fotoUrl: m['foto_url'] as String?,
        ativo: (m['ativo'] as int?) == 1,
        revoked: (m['revoked'] as int?) == 1,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
      );

  Usuario copyWith({
    int? id,
    String? firebaseUid,
    String? nome,
    String? email,
    UserRole? role,
    double? comissaoPercentual,
    String? fotoUrl,
    bool? ativo,
    bool? revoked,
    String? barbeariaId,
    String? firebaseId,
  }) =>
      Usuario(
        id: id ?? this.id,
        firebaseUid: firebaseUid ?? this.firebaseUid,
        nome: nome ?? this.nome,
        email: email ?? this.email,
        role: role ?? this.role,
        comissaoPercentual: comissaoPercentual ?? this.comissaoPercentual,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        ativo: ativo ?? this.ativo,
        revoked: revoked ?? this.revoked,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
      );
}
