import 'package:flutter/material.dart';
import '../../services/license_service.dart';
import '../../utils/app_config.dart';
import '../../utils/constants.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _ctrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _svc = LicenseService();

  bool _loading = false;
  String? _error;

  Future<void> _activate() async {
    if (!_form.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });
    try {
      await _svc.activate(_ctrl.text.trim());
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ValidationException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      AppConfig.logoAsset,
                      height: 100,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.content_cut,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ativação de Licença',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _ctrl,
                      maxLength: AppConstants.licenseKeyLength,
                      decoration: const InputDecoration(
                        labelText: 'Chave de Licença',
                        hintText: 'Insira a chave de 24 caracteres',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        counterText: '',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v == null || v.trim().length != AppConstants.licenseKeyLength) {
                          return 'A chave deve ter exatamente 24 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _activate,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Ativar Licença'),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Contate o suporte para obter sua chave de licença.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
