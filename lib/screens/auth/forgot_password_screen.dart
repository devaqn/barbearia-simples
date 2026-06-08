import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.sendPasswordReset(_emailCtrl.text.trim());
    if (ok && mounted) {
      UiHelpers.showSuccess(context, 'E-mail de recuperação enviado.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Consumer<AuthController>(
          builder: (context, ctrl, _) => Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Insira seu e-mail para receber o link de redefinição de senha.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (ctrl.errorMsg != null)
                  DsErrorBanner(message: ctrl.errorMsg!, onDismiss: ctrl.clearError),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _send,
                  child: ctrl.isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
