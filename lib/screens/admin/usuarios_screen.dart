import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../database/database_helper.dart';
import '../../models/usuario.dart';
import '../../services/session_manager.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _usuarios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final session = context.read<SessionManager>();
    final db = context.read<DatabaseHelper>();
    final rows = await db.query(
      'usuarios',
      where: 'barbearia_id = ? AND ativo = 1',
      whereArgs: [session.barbeariaId],
    );
    if (mounted) {
      setState(() {
        _usuarios = rows.map(Usuario.fromMap).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCriarBarbeiro(),
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? DsEmptyState(
                  message: 'Nenhum usuário encontrado.',
                  onAction: _showCriarBarbeiro,
                  actionLabel: 'Criar Barbeiro',
                )
              : ListView.builder(
                  itemCount: _usuarios.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: CircleAvatar(child: Text(_usuarios[i].nome[0].toUpperCase())),
                    title: Text(_usuarios[i].nome),
                    subtitle: Text('${_usuarios[i].role.name} · ${_usuarios[i].email}'),
                    trailing: Text(
                      Fmt.percent(_usuarios[i].comissaoPercentual),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
    );
  }

  void _showCriarBarbeiro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CriarBarbeiroForm(onCreated: _load),
    );
  }
}

class _CriarBarbeiroForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CriarBarbeiroForm({required this.onCreated});

  @override
  State<_CriarBarbeiroForm> createState() => _CriarBarbeiroFormState();
}

class _CriarBarbeiroFormState extends State<_CriarBarbeiroForm> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _comissao = TextEditingController(text: '50');

  @override
  void dispose() { _nome.dispose(); _email.dispose(); _pass.dispose(); _comissao.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Criar Barbeiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DsTextField(controller: _nome, label: 'Nome', validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            DsTextField(controller: _email, label: 'E-mail', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            DsTextField(controller: _pass, label: 'Senha inicial', obscureText: true),
            const SizedBox(height: 12),
            DsTextField(controller: _comissao, label: 'Comissão (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 20),
            Consumer<AuthController>(
              builder: (context, ctrl, _) => ElevatedButton(
                onPressed: ctrl.isLoading ? null : () async {
                  if (!_form.currentState!.validate()) return;
                  final ok = await ctrl.criarBarbeiro(
                    email: _email.text.trim(),
                    password: _pass.text,
                    nome: _nome.text.trim(),
                    comissao: double.tryParse(_comissao.text) ?? 50,
                  );
                  if (ok && context.mounted) {
                    Navigator.pop(context);
                    UiHelpers.showSuccess(context, 'Barbeiro criado com sucesso!');
                    widget.onCreated();
                  } else if (ctrl.errorMsg != null && context.mounted) {
                    UiHelpers.showError(context, ctrl.errorMsg!);
                  }
                },
                child: ctrl.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Criar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
