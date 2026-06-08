import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/servico_controller.dart';
import '../../models/servico.dart';
import '../../services/session_manager.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicoController>().carregar(somenteAtivos: !_showInactive);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Ocultar inativos' : 'Mostrar inativos',
            onPressed: () {
              setState(() => _showInactive = !_showInactive);
              context.read<ServicoController>().carregar(somenteAtivos: !_showInactive);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ServicoController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
          if (ctrl.servicos.isEmpty) {
            return DsEmptyState(
              message: 'Nenhum serviço cadastrado.',
              icon: Icons.design_services_outlined,
              onAction: () => _showForm(context),
            );
          }
          return ListView.builder(
            itemCount: ctrl.servicos.length,
            itemBuilder: (_, i) => _ServicoTile(
              ctrl.servicos[i],
              onToggle: () => ctrl.toggleAtivo(ctrl.servicos[i]),
              onEdit: () => _showForm(context, servico: ctrl.servicos[i]),
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, {Servico? servico}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ServicoForm(servico: servico),
    );
  }
}

class _ServicoTile extends StatelessWidget {
  final Servico servico;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _ServicoTile(this.servico, {required this.onToggle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: servico.ativo ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade200,
        child: Icon(Icons.design_services, color: servico.ativo ? Theme.of(context).colorScheme.primary : Colors.grey),
      ),
      title: Text(servico.nome, style: TextStyle(color: servico.ativo ? null : Colors.grey)),
      subtitle: Text('${Fmt.duration(servico.duracaoMinutos)} • Comissão: ${Fmt.percent(servico.comissaoPercentual)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Fmt.currency(servico.preco), style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
          Switch(value: servico.ativo, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }
}

class _ServicoForm extends StatefulWidget {
  final Servico? servico;
  const _ServicoForm({this.servico});

  @override
  State<_ServicoForm> createState() => _ServicoFormState();
}

class _ServicoFormState extends State<_ServicoForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _preco;
  late final TextEditingController _duracao;
  late final TextEditingController _comissao;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.servico?.nome);
    _preco = TextEditingController(text: widget.servico?.preco.toStringAsFixed(2));
    _duracao = TextEditingController(text: '${widget.servico?.duracaoMinutos ?? 30}');
    _comissao = TextEditingController(text: '${widget.servico?.comissaoPercentual ?? 50}');
  }

  @override
  void dispose() {
    _nome.dispose(); _preco.dispose(); _duracao.dispose(); _comissao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionManager>();
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.servico == null ? 'Novo Serviço' : 'Editar Serviço',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DsTextField(controller: _nome, label: 'Nome', validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: DsTextField(controller: _preco, label: 'Preço (R\$)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: DsTextField(controller: _duracao, label: 'Duração (min)', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            DsTextField(controller: _comissao, label: 'Comissão (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final ctrl = context.read<ServicoController>();
                final s = Servico(
                  id: widget.servico?.id,
                  nome: _nome.text.trim(),
                  preco: double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0,
                  duracaoMinutos: int.tryParse(_duracao.text) ?? 30,
                  comissaoPercentual: double.tryParse(_comissao.text.replaceAll(',', '.')) ?? 50,
                  barbeariaId: session.barbeariaId,
                  firebaseId: widget.servico?.firebaseId,
                );
                final ok = await ctrl.salvar(s);
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  UiHelpers.showSuccess(context, 'Serviço salvo!');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
