import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/license_service.dart';
import '../../utils/app_config.dart';
import '../../utils/app_routes.dart';
import '../../utils/security_utils.dart';
import '../../widgets/ds_widgets.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _barbeariaId;

  @override
  void initState() {
    super.initState();
    _loadBarbeariaId();
  }

  Future<void> _loadBarbeariaId() async {
    final license = context.read<LicenseService>();
    final key = await license.getKey();
    if (!mounted) return;
    setState(() => _barbeariaId = key);
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (!_form.currentState!.validate()) return;
    if (_barbeariaId == null) return;

    final ctrl = context.read<AuthController>();
    final ok = await ctrl.bootstrapAdmin(
      email: _email.text.trim(),
      password: _senha.text,
      nome: SecurityUtils.sanitizeName(_nome.text.trim()),
      barbeariaId: _barbeariaId!,
    );

    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (ctrl.errorMsg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.errorMsg!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Consumer<AuthController>(
                builder: (_, ctrl, __) => Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.store_mall_directory_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(AppConfig.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Configuração inicial', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 8),
                      Text('Crie a conta do administrador', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 32),
                      if (ctrl.errorMsg != null)
                        DsErrorBanner(message: ctrl.errorMsg!, onDismiss: ctrl.clearError),
                      const SizedBox(height: 8),
                      DsTextField(
                        controller: _nome,
                        label: 'Seu nome completo',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      DsTextField(
                        controller: _email,
                        label: 'E-mail',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'E-mail obrigatório';
                          if (!SecurityUtils.isValidEmail(v.trim())) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DsTextField(
                        controller: _senha,
                        label: 'Senha',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscure1,
                        suffix: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Senha obrigatória';
                          if (!SecurityUtils.isStrongPassword(v)) return 'Mín. 8 chars: maiúscula, número e símbolo';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DsTextField(
                        controller: _confirma,
                        label: 'Confirmar senha',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscure2,
                        suffix: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                        validator: (v) => v != _senha.text ? 'Senhas não conferem' : null,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: ctrl.isLoading ? null : _criar,
                        child: ctrl.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Criar conta de administrador'),
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
