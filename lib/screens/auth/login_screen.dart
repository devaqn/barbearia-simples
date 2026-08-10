import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../screens/legal/termos_screen.dart';
import '../../services/session_manager.dart';
import '../../utils/app_config.dart';
import '../../utils/app_routes.dart';
import '../../widgets/ds_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      // Check if terms were accepted
      final termosAceitos = await TermosScreen.foiAceito();
      if (!termosAceitos && mounted) {
        final accepted = await Navigator.pushNamed(context, AppRoutes.termos);
        if (accepted != true) {
          // User declined terms — log out
          await ctrl.logout();
          return;
        }
      }

      if (mounted) {
        final session = context.read<SessionManager>();
        final route = session.isAdmin ? AppRoutes.dashboard : AppRoutes.barberDashboard;
        Navigator.pushReplacementNamed(context, route);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Consumer<AuthController>(
                builder: (context, ctrl, _) => Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        AppConfig.logoAsset,
                        height: 90,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.content_cut,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConfig.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConfig.tagline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(height: 40),
                      if (ctrl.errorMsg != null)
                        DsErrorBanner(
                          message: ctrl.errorMsg!,
                          onDismiss: ctrl.clearError,
                        ),
                      const SizedBox(height: 8),
                      DsTextField(
                        controller: _emailCtrl,
                        label: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'E-mail obrigatório';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DsTextField(
                        controller: _passCtrl,
                        label: 'Senha',
                        obscureText: _obscure,
                        prefixIcon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Senha obrigatória';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.forgotPassword),
                          child: const Text('Esqueci a senha'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: ctrl.isLoading ? null : _login,
                        child: ctrl.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
