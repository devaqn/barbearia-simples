import 'assinatura.dart';

class Cliente {
  final int? id;
  final String nome;
  final String telefone;
  final String? email;
  final DateTime? dataNascimento;
  final int totalAtendimentos;
  final double totalGasto;
  final int pontosFidelidade;
  final bool isAssinante;
  final String barbeariaId;
  final String? firebaseId;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;
  final Assinatura? assinatura;

  const Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    this.email,
    this.dataNascimento,
    this.totalAtendimentos = 0,
    this.totalGasto = 0.0,
    this.pontosFidelidade = 0,
    this.isAssinante = false,
    required this.barbeariaId,
    this.firebaseId,
    this.criadoEm,
    this.atualizadoEm,
    this.assinatura,
  });

  String get assinaturaStatus {
    if (!isAssinante || assinatura == null) return 'Não assinante';
    if (assinatura!.estaEmDia) return 'Ativo';
    return 'Vencido';
  }

  bool get fazAniversarioHoje {
    if (dataNascimento == null) return false;
    final now = DateTime.now();
    return dataNascimento!.month == now.month && dataNascimento!.day == now.day;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'telefone': telefone,
        'email': email,
        'data_nascimento': dataNascimento?.toIso8601String(),
        'total_atendimentos': totalAtendimentos,
        'total_gasto': totalGasto,
        'pontos_fidelidade': pontosFidelidade,
        'is_assinante': isAssinante ? 1 : 0,
        'barbearia_id': barbeariaId,
        'firebase_id': firebaseId,
        'criado_em': criadoEm?.toIso8601String(),
        'atualizado_em': atualizadoEm?.toIso8601String(),
      };

  factory Cliente.fromMap(Map<String, dynamic> m) => Cliente(
        id: m['id'] as int?,
        nome: m['nome'] as String,
        telefone: m['telefone'] as String,
        email: m['email'] as String?,
        dataNascimento: m['data_nascimento'] != null
            ? DateTime.tryParse(m['data_nascimento'] as String)
            : null,
        totalAtendimentos: (m['total_atendimentos'] as int?) ?? 0,
        totalGasto: (m['total_gasto'] as num?)?.toDouble() ?? 0.0,
        pontosFidelidade: (m['pontos_fidelidade'] as int?) ?? 0,
        isAssinante: (m['is_assinante'] as int?) == 1,
        barbeariaId: m['barbearia_id'] as String,
        firebaseId: m['firebase_id'] as String?,
        criadoEm: m['criado_em'] != null ? DateTime.tryParse(m['criado_em'] as String) : null,
        atualizadoEm: m['atualizado_em'] != null ? DateTime.tryParse(m['atualizado_em'] as String) : null,
      );

  Cliente copyWith({
    int? id,
    String? nome,
    String? telefone,
    String? email,
    DateTime? dataNascimento,
    int? totalAtendimentos,
    double? totalGasto,
    int? pontosFidelidade,
    bool? isAssinante,
    String? barbeariaId,
    String? firebaseId,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    Assinatura? assinatura,
  }) =>
      Cliente(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        telefone: telefone ?? this.telefone,
        email: email ?? this.email,
        dataNascimento: dataNascimento ?? this.dataNascimento,
        totalAtendimentos: totalAtendimentos ?? this.totalAtendimentos,
        totalGasto: totalGasto ?? this.totalGasto,
        pontosFidelidade: pontosFidelidade ?? this.pontosFidelidade,
        isAssinante: isAssinante ?? this.isAssinante,
        barbeariaId: barbeariaId ?? this.barbeariaId,
        firebaseId: firebaseId ?? this.firebaseId,
        criadoEm: criadoEm ?? this.criadoEm,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
        assinatura: assinatura ?? this.assinatura,
      );
}
