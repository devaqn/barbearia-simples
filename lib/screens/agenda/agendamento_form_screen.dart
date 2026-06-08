import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/agenda_controller.dart';
import '../../controllers/cliente_controller.dart';
import '../../controllers/servico_controller.dart';
import '../../models/agendamento.dart';
import '../../models/cliente.dart';
import '../../models/servico.dart';
import '../../models/usuario.dart';
import '../../database/database_helper.dart';
import '../../services/session_manager.dart';
import '../../utils/formatters.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class AgendamentoFormScreen extends StatefulWidget {
  const AgendamentoFormScreen({super.key});

  @override
  State<AgendamentoFormScreen> createState() => _AgendamentoFormScreenState();
}

class _AgendamentoFormScreenState extends State<AgendamentoFormScreen> {
  final _form = GlobalKey<FormState>();
  final _obs = TextEditingController();
  Cliente? _cliente;
  Servico? _servico;
  Usuario? _barbeiro;
  DateTime _dataHora = DateTime.now().add(const Duration(hours: 1));
  List<Usuario> _barbeiros = [];
  bool _loadingBarbeiros = true;
  Agendamento? _editing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is Agendamento) _editing = arg;

      // Load supporting data
      context.read<ClienteController>().carregar();
      context.read<ServicoController>().carregar();
      _loadBarbeiros();
    }
  }

  Future<void> _loadBarbeiros() async {
    final session = context.read<SessionManager>();
    final db = context.read<DatabaseHelper>();
    final rows = await db.query(
      'usuarios',
      where: "barbearia_id = ? AND ativo = 1 AND revoked = 0",
      whereArgs: [session.barbeariaId],
    );
    _barbeiros = rows.map(Usuario.fromMap).toList();
    if (mounted) setState(() => _loadingBarbeiros = false);
  }

  @override
  void dispose() { _obs.dispose(); super.dispose(); }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dataHora));
    if (time == null) return;
    setState(() {
      _dataHora = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_cliente == null) { UiHelpers.showError(context, 'Selecione um cliente.'); return; }
    if (_barbeiro == null) { UiHelpers.showError(context, 'Selecione um barbeiro.'); return; }

    final duracao = _servico?.duracaoMinutos ?? 30;
    final session = context.read<SessionManager>();
    final ctrl = context.read<AgendaController>();

    final ag = Agendamento(
      id: _editing?.id,
      clienteId: _cliente!.id!,
      barbeiroId: _barbeiro!.id!,
      servicoId: _servico?.id,
      dataHoraInicio: _dataHora,
      dataHoraFim: _dataHora.add(Duration(minutes: duracao)),
      status: _editing?.status ?? 'pendente',
      observacoes: _obs.text.trim().isNotEmpty ? _obs.text.trim() : null,
      barbeariaId: _editing?.barbeariaId ?? session.barbeariaId,
      firebaseId: _editing?.firebaseId,
    );

    final ok = await ctrl.salvar(ag);
    if (ok && mounted) {
      UiHelpers.showSuccess(context, _editing == null ? 'Agendamento criado!' : 'Agendamento atualizado!');
      Navigator.pop(context, true);
    } else if (ctrl.errorMsg != null && mounted) {
      UiHelpers.showError(context, ctrl.errorMsg!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing == null ? 'Novo Agendamento' : 'Editar Agendamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cliente
              Consumer<ClienteController>(
                builder: (_, ctrl, __) => DropdownButtonFormField<Cliente>(
                  value: _cliente,
                  hint: const Text('Selecionar cliente'),
                  items: ctrl.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))).toList(),
                  onChanged: (v) => setState(() => _cliente = v),
                  validator: (v) => v == null ? 'Selecione um cliente' : null,
                  decoration: const InputDecoration(labelText: 'Cliente', prefixIcon: Icon(Icons.person_outline)),
                ),
              ),
              const SizedBox(height: 16),
              // Barbeiro
              _loadingBarbeiros
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<Usuario>(
                      value: _barbeiro,
                      hint: const Text('Selecionar barbeiro'),
                      items: _barbeiros.map((u) => DropdownMenuItem(value: u, child: Text(u.nome))).toList(),
                      onChanged: (v) => setState(() => _barbeiro = v),
                      validator: (v) => v == null ? 'Selecione um barbeiro' : null,
                      decoration: const InputDecoration(labelText: 'Barbeiro', prefixIcon: Icon(Icons.cut_outlined)),
                    ),
              const SizedBox(height: 16),
              // Serviço
              Consumer<ServicoController>(
                builder: (_, ctrl, __) => DropdownButtonFormField<Servico>(
                  value: _servico,
                  hint: const Text('Selecionar serviço (opcional)'),
                  items: ctrl.servicos.map((s) => DropdownMenuItem(value: s, child: Text('${s.nome} · ${Fmt.duration(s.duracaoMinutos)}'))).toList(),
                  onChanged: (v) => setState(() => _servico = v),
                  decoration: const InputDecoration(labelText: 'Serviço', prefixIcon: Icon(Icons.design_services_outlined)),
                ),
              ),
              const SizedBox(height: 16),
              // Data/Hora
              DsTextField(
                controller: TextEditingController(text: Fmt.dateTime(_dataHora)),
                label: 'Data e Hora',
                prefixIcon: Icons.event,
                readOnly: true,
                onTap: _pickDateTime,
              ),
              if (_servico != null) ...[
                const SizedBox(height: 4),
                Text('Término previsto: ${Fmt.time(_dataHora.add(Duration(minutes: _servico!.duracaoMinutos)))}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              DsTextField(controller: _obs, label: 'Observações (opcional)', maxLines: 3),
              const SizedBox(height: 28),
              Consumer<AgendaController>(
                builder: (_, ctrl, __) => ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _salvar,
                  child: ctrl.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_editing == null ? 'Confirmar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
