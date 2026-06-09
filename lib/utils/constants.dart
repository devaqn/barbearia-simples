abstract class AppConstants {
  // License
  static const int licenseKeyLength = 24;
  static const String licenseStorageKey = 'barberos_license_key';
  static const String shopIdStorageKey = 'barberos_shop_id';

  // SQLite
  static const String dbName = 'barberos.db';
  static const int dbVersion = 2;

  // Firestore collections
  static const String colBarbearias = 'barbearias';
  static const String colUsuarios = 'usuarios';
  static const String colClientes = 'clientes';
  static const String colServicos = 'servicos';
  static const String colProdutos = 'produtos';
  static const String colFornecedores = 'fornecedores';
  static const String colAtendimentos = 'atendimentos';
  static const String colAgendamentos = 'agendamentos';
  static const String colDespesas = 'despesas';
  static const String colMovimentosEstoque = 'movimentos_estoque';
  static const String colCaixas = 'caixas';
  static const String colComandas = 'comandas';
  static const String colComandasItens = 'comandas_itens';
  static const String colComissoes = 'comissoes';
  static const String colAssinaturas = 'assinaturas';

  // Pagination
  static const int pageSize = 20;

  // Validation
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxObsLength = 300;
  static const int maxEmailLength = 150;
  static const int maxPhoneLength = 20;

  // Commission defaults
  static const double defaultCommissionPercent = 50.0;

  // Fidelity
  static const int pointsPerReal = 1;

  // Subscription plans
  static const String planBasico = 'basico';
  static const String planPremium = 'premium';
  static const String planVip = 'vip';

  // Cache duration
  static const Duration cacheDuration = Duration(minutes: 10);

  // MP
  static const String mpPublicKey = String.fromEnvironment('MP_PUBLIC_KEY');
  static const String mpAccessToken = String.fromEnvironment('MP_ACCESS_TOKEN');
}
