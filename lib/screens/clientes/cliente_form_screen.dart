import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente.dart';
import '../../services/session_manager.dart';
import '../../utils/formatters.dart';
import '../../utils/security_utils.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _dataNasc = TextEditingController();
  DateTime? _dataNascimento;
  Cliente? _editing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is Cliente) {
        _editing = arg;
        _nome.text = arg.nome;
        _telefone.text = arg.telefone;
        _email.text = arg.email ?? '';
        _dataNascimento = arg.dataNascimento;
        if (arg.dataNascimento != null) {
          _dataNasc.text = Fmt.date(arg.dataNascimento);
        }
      }
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    _dataNasc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
        _dataNasc.text = Fmt.date(picked);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final session = context.read<SessionManager>();
    final ctrl = context.read<ClienteController>();

    final cliente = Cliente(
      id: _editing?.id,
      nome: SecurityUtils.sanitizeName(_nome.text.trim()),
      telefone: SecurityUtils.sanitizePhone(_telefone.text.trim()),
      email: _email.text.trim().isNotEmpty ? SecurityUtils.sanitizeEmail(_email.text.trim()) : null,
      dataNascimento: _dataNascimento,
      barbeariaId: _editing?.barbeariaId ?? session.barbeariaId,
      firebaseId: _editing?.firebaseId,
      totalAtendimentos: _editing?.totalAtendimentos ?? 0,
      totalGasto: _editing?.totalGasto ?? 0.0,
      pontosFidelidade: _editing?.pontosFidelidade ?? 0,
      isAssinante: _editing?.isAssinante ?? false,
    );

    final ok = await ctrl.salvar(cliente);
    if (ok && mounted) {
      UiHelpers.showSuccess(context, _editing == null ? 'Cliente cadastrado!' : 'Cliente atualizado!');
      Navigator.pop(context, true);
    } else if (ctrl.errorMsg != null && mounted) {
      UiHelpers.showError(context, ctrl.errorMsg!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'Novo Cliente' : 'Editar Cliente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsTextField(
                controller: _nome,
                label: 'Nome completo',
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DsTextField(
                controller: _telefone,
                label: 'Telefone / WhatsApp',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Telefone obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DsTextField(
                controller: _email,
                label: 'E-mail (opcional)',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && !SecurityUtils.isValidEmail(v.trim())) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DsTextField(
                controller: _dataNasc,
                label: 'Data de nascimento (opcional)',
                prefixIcon: Icons.cake_outlined,
                readOnly: true,
                onTap: _pickDate,
                suffix: _dataNascimento != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _dataNascimento = null;
                          _dataNasc.clear();
                        }),
                      )
                    : null,
              ),
              const SizedBox(height: 28),
              Consumer<ClienteController>(
                builder: (_, ctrl, __) => ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _salvar,
                  child: ctrl.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_editing == null ? 'Cadastrar' : 'Salvar alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
