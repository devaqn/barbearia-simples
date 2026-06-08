import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/profile_photo_service.dart';
import '../../services/session_manager.dart';
import '../../utils/security_utils.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formSenha = GlobalKey<FormState>();
  final _novaSenha = TextEditingController();
  final _confirmaSenha = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionManager>();
    _fotoPath = session.currentUser?.fotoUrl;
  }

  @override
  void dispose() {
    _novaSenha.dispose();
    _confirmaSenha.dispose();
    super.dispose();
  }

  Future<void> _trocarFoto(bool camera) async {
    final session = context.read<SessionManager>();
    if (session.userId == null) return;
    try {
      final svc = context.read<ProfilePhotoService>();
      final path = camera ? await svc.pickFromCamera() : await svc.pickFromGallery();
      if (path != null) {
        await svc.updateUserPhoto(session.userId!, path);
        setState(() => _fotoPath = path);
        if (mounted) UiHelpers.showSuccess(context, 'Foto atualizada!');
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Erro ao atualizar foto: $e');
    }
  }

  void _showFotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Câmera'), onTap: () { Navigator.pop(context); _trocarFoto(true); }),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria'), onTap: () { Navigator.pop(context); _trocarFoto(false); }),
        ]),
      ),
    );
  }

  Future<void> _alterarSenha() async {
    if (!_formSenha.currentState!.validate()) return;
    final ctrl = context.read<AuthController>();
    final ok = await ctrl.changePassword(_novaSenha.text);
    if (ok && mounted) {
      UiHelpers.showSuccess(context, 'Senha alterada com sucesso!');
      _novaSenha.clear();
      _confirmaSenha.clear();
    } else if (ctrl.errorMsg != null && mounted) {
      UiHelpers.showError(context, ctrl.errorMsg!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _fotoPath != null ? FileImage(File(_fotoPath!)) : null,
                    child: _fotoPath == null
                        ? Text(user?.nome.isNotEmpty == true ? user!.nome[0].toUpperCase() : '?', style: const TextStyle(fontSize: 36))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        padding: EdgeInsets.zero,
                        onPressed: _showFotoOptions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informações da conta', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Nome', value: user?.nome ?? '—'),
                  _InfoRow(label: 'E-mail', value: user?.email ?? '—'),
                  _InfoRow(label: 'Função', value: user?.isAdmin == true ? 'Administrador' : 'Barbeiro'),
                  if (user?.isAdmin == false)
                    _InfoRow(label: 'Comissão', value: '${user?.comissaoPercentual.toStringAsFixed(0)}%'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Alterar senha', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Consumer<AuthController>(
              builder: (_, ctrl, __) => Form(
                key: _formSenha,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsTextField(
                      controller: _novaSenha,
                      label: 'Nova senha',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure1,
                      suffix: IconButton(icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure1 = !_obscure1)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Senha obrigatória';
                        if (!SecurityUtils.isStrongPassword(v)) return 'Mín. 8 chars: maiúscula, número e símbolo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DsTextField(
                      controller: _confirmaSenha,
                      label: 'Confirmar nova senha',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure2,
                      suffix: IconButton(icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure2 = !_obscure2)),
                      validator: (v) => v != _novaSenha.text ? 'Senhas não conferem' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: ctrl.isLoading ? null : _alterarSenha,
                      child: ctrl.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Alterar senha'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

