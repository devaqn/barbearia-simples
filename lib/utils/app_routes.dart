abstract class AppRoutes {
  static const String license = '/license';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String barberDashboard = '/barber-dashboard';

  // Admin
  static const String adminUsuarios = '/admin/usuarios';
  static const String adminSetup = '/admin/setup';

  // Clientes
  static const String clientes = '/clientes';
  static const String clienteDetalhe = '/clientes/detalhe';
  static const String clienteForm = '/clientes/form';

  // Serviços
  static const String servicos = '/servicos';
  static const String servicoForm = '/servicos/form';

  // Produtos
  static const String produtos = '/produtos';
  static const String produtoForm = '/produtos/form';
  static const String estoque = '/estoque';

  // Comanda
  static const String comandas = '/comandas';
  static const String comandaDetalhe = '/comanda/detalhe';
  static const String comandaAberta = '/comanda/aberta';

  // Atendimentos
  static const String atendimentos = '/atendimentos';

  // Agenda
  static const String agenda = '/agenda';
  static const String agendamentoForm = '/agenda/form';

  // Financeiro
  static const String financeiro = '/financeiro';
  static const String despesas = '/financeiro/despesas';
  static const String caixa = '/caixa';

  // Assinaturas
  static const String assinaturas = '/assinaturas';
  static const String assinaturaDetalhe = '/assinaturas/detalhe';

  // Relatórios / Analytics
  static const String relatorios = '/relatorios';
  static const String analytics = '/analytics';
  static const String ranking = '/ranking';

  // Perfil
  static const String perfil = '/perfil';

  // Avaliações
  static const String avaliacoes = '/avaliacoes';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Legal
  static const String termos = '/legal/termos';
  static const String privacidade = '/legal/privacidade';

  // Configurações
  static const String notificationSettings = '/settings/notificacoes';

  // Booking (public, no auth)
  static const String booking = '/booking';
  static const String bookingConfirmation = '/booking/confirmation';

  // Admin - Booking link
  static const String bookingLink = '/admin/booking-link';
}
