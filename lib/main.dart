import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/agenda_controller.dart';
import 'controllers/atendimento_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cliente_controller.dart';
import 'controllers/comanda_controller.dart';
import 'controllers/financeiro_controller.dart';
import 'controllers/produto_controller.dart';
import 'controllers/servico_controller.dart';
import 'database/database_helper.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_setup_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/usuarios_screen.dart';
import 'screens/agenda/agenda_screen.dart';
import 'screens/agenda/agendamento_form_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/assinaturas/assinaturas_screen.dart';
import 'screens/atendimentos/atendimentos_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/perfil_screen.dart';
import 'screens/barbeiro/barbeiro_dashboard_screen.dart';
import 'screens/caixa/caixa_screen.dart';
import 'screens/clientes/cliente_detalhe_screen.dart';
import 'screens/clientes/cliente_form_screen.dart';
import 'screens/clientes/clientes_screen.dart';
import 'screens/comanda/comanda_aberta_screen.dart';
import 'screens/comanda/comandas_screen.dart';
import 'screens/estoque/estoque_screen.dart';
import 'screens/financeiro/financeiro_screen.dart';
import 'screens/license/license_screen.dart';
import 'screens/produtos/produtos_screen.dart';
import 'screens/ranking/ranking_screen.dart';
import 'screens/relatorios/relatorios_screen.dart';
import 'screens/servicos/servico_form_screen.dart';
import 'screens/servicos/servicos_screen.dart';
import 'services/agenda_service.dart';
import 'services/assinatura_service.dart';
import 'services/atendimento_service.dart';
import 'services/auth_service.dart';
import 'services/caixa_service.dart';
import 'services/cliente_service.dart';
import 'services/comanda_service.dart';
import 'services/connectivity_service.dart';
import 'services/dashboard_service.dart';
import 'services/financeiro_service.dart';
import 'services/firebase_context_service.dart';
import 'services/license_service.dart';
import 'services/produto_service.dart';
import 'services/profile_photo_service.dart';
import 'services/realtime_sync_service.dart';
import 'services/servico_service.dart';
import 'services/session_manager.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

// Compile-time check for Firebase credentials
const _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _hasFirebaseConfig = _firebaseAppId != '' && _firebaseProjectId != '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  if (_hasFirebaseConfig) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      firebaseReady = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[main] Firebase init failed (offline mode): $e');
    }
  } else {
    if (kDebugMode) debugPrint('[main] Firebase credentials not configured — running offline.');
  }

  final db = DatabaseHelper.instance;
  try {
    await db.database;
  } catch (e, st) {
    if (kDebugMode) debugPrint('[main] DB init error: $e\n$st');
  }

  final conn = ConnectivityService();
  final ctx = FirebaseContextService();
  final session = SessionManager();
  final license = LicenseService();

  final authSvc = AuthService(ctx);
  final clienteSvc = ClienteService(db, conn, ctx);
  final servicoSvc = ServicoService(db, conn, ctx);
  final produtoSvc = ProdutoService(db, conn, ctx);
  final comandaSvc = ComandaService(db, conn, ctx, clienteSvc);
  final financeiroSvc = FinanceiroService(db, conn, ctx);
  final agendaSvc = AgendaService(db, conn, ctx);
  final assinaturaSvc = AssinaturaService(db, conn, ctx);
  final atendimentoSvc = AtendimentoService(db);
  final dashboardSvc = DashboardService(db);
  final caixaSvc = CaixaService(db);
  final profilePhotoSvc = ProfilePhotoService(db);
  final realtimeSync = RealtimeSyncService(db, conn, ctx);

  if (firebaseReady) {
    conn.addListener(() {
      if (conn.isOnline) {
        realtimeSync.startListening();
        realtimeSync.syncPendingRecords(session.barbeariaId);
      }
    });
    if (conn.isOnline) realtimeSync.startListening();
  }

  bool isActivated = false;
  try {
    isActivated = await license.isActivated();
  } catch (e) {
    if (kDebugMode) debugPrint('[main] License check error: $e');
  }
  final initialRoute = isActivated ? AppRoutes.login : AppRoutes.license;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: conn),
        ChangeNotifierProvider.value(value: session),
        Provider.value(value: db),
        Provider.value(value: license),
        Provider.value(value: ctx),
        Provider.value(value: dashboardSvc),
        Provider.value(value: assinaturaSvc),
        Provider.value(value: caixaSvc),
        Provider.value(value: clienteSvc),
        Provider.value(value: servicoSvc),
        Provider.value(value: produtoSvc),
        Provider.value(value: financeiroSvc),
        Provider.value(value: atendimentoSvc),
        Provider.value(value: profilePhotoSvc),
        Provider.value(value: realtimeSync),
        ChangeNotifierProvider(create: (_) => AuthController(authSvc, session)),
        ChangeNotifierProvider(create: (_) => ClienteController(clienteSvc, session)),
        ChangeNotifierProvider(create: (_) => ServicoController(servicoSvc, session)),
        ChangeNotifierProvider(create: (_) => ProdutoController(produtoSvc, session)),
        ChangeNotifierProvider(create: (_) => ComandaController(comandaSvc, session)),
        ChangeNotifierProvider(create: (_) => FinanceiroController(financeiroSvc, session)),
        ChangeNotifierProvider(create: (_) => AgendaController(agendaSvc, session)),
        ChangeNotifierProvider(create: (_) => AtendimentoController(atendimentoSvc, session)),
      ],
      child: BarberOSApp(initialRoute: initialRoute),
    ),
  );
}

class BarberOSApp extends StatelessWidget {
  final String initialRoute;

  const BarberOSApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: initialRoute,
      routes: {
        AppRoutes.license: (_) => const LicenseScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.adminSetup: (_) => const AdminSetupScreen(),
        AppRoutes.dashboard: (_) => const _AuthGuard(adminOnly: true, child: DashboardScreen()),
        AppRoutes.barberDashboard: (_) => const _AuthGuard(child: BarbeiroDashboardScreen()),
        AppRoutes.clientes: (_) => const _AuthGuard(child: ClientesScreen()),
        AppRoutes.clienteDetalhe: (_) => const _AuthGuard(child: ClienteDetalheScreen()),
        AppRoutes.clienteForm: (_) => const _AuthGuard(child: ClienteFormScreen()),
        AppRoutes.servicos: (_) => const _AuthGuard(adminOnly: true, child: ServicosScreen()),
        AppRoutes.servicoForm: (_) => const _AuthGuard(adminOnly: true, child: ServicoFormScreen()),
        AppRoutes.produtos: (_) => const _AuthGuard(adminOnly: true, child: ProdutosScreen()),
        AppRoutes.estoque: (_) => const _AuthGuard(adminOnly: true, child: EstoqueScreen()),
        AppRoutes.financeiro: (_) => const _AuthGuard(adminOnly: true, child: FinanceiroScreen()),
        AppRoutes.caixa: (_) => const _AuthGuard(child: CaixaScreen()),
        AppRoutes.assinaturas: (_) => const _AuthGuard(adminOnly: true, child: AssinaturasScreen()),
        AppRoutes.relatorios: (_) => const _AuthGuard(adminOnly: true, child: RelatoriosScreen()),
        AppRoutes.analytics: (_) => const _AuthGuard(adminOnly: true, child: AnalyticsScreen()),
        AppRoutes.ranking: (_) => const _AuthGuard(adminOnly: true, child: RankingScreen()),
        AppRoutes.agenda: (_) => const _AuthGuard(child: AgendaScreen()),
        AppRoutes.agendamentoForm: (_) => const _AuthGuard(child: AgendamentoFormScreen()),
        AppRoutes.atendimentos: (_) => const _AuthGuard(child: AtendimentosScreen()),
        AppRoutes.comandas: (_) => const _AuthGuard(child: ComandasScreen()),
        AppRoutes.comandaAberta: (_) => const _AuthGuard(child: ComandaAbertaScreen()),
        AppRoutes.adminUsuarios: (_) => const _AuthGuard(adminOnly: true, child: UsuariosScreen()),
        AppRoutes.perfil: (_) => const _AuthGuard(child: PerfilScreen()),
      },
    );
  }
}

class _AuthGuard extends StatelessWidget {
  final Widget child;
  final bool adminOnly;

  const _AuthGuard({required this.child, this.adminOnly = false});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();

    if (!session.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (adminOnly && !session.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.barberDashboard);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
