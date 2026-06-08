import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/atendimento_controller.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/atendimento.dart';
import '../../models/cliente.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/assinante_badge.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/ui_helpers.dart';

class ClienteDetalheScreen extends StatefulWidget {
  const ClienteDetalheScreen({super.key});

  @override
  State<ClienteDetalheScreen> createState() => _ClienteDetalheScreenState();
}

class _ClienteDetalheScreenState extends State<ClienteDetalheScreen> {
  late Cliente _cliente;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _cliente = ModalRoute.of(context)!.settings.arguments as Cliente;
      _load();
    }
  }

  Future<void> _load() async {
    if (_cliente.id == null) return;
    await context.read<AtendimentoController>().carregar(clienteId: _cliente.id);
  }

  Future<void> _editar() async {
    final result = await Navigator.pushNamed(context, AppRoutes.clienteForm, arguments: _cliente);
    if (result == true && mounted) {
      final ctrl = context.read<ClienteController>();
      await ctrl.carregar();
      final updated = ctrl.clientes.firstWhere((c) => c.id == _cliente.id, orElse: () => _cliente);
      setState(() => _cliente = updated);
    }
  }

  Future<void> _excluir() async {
    final ok = await UiHelpers.showConfirmDialog(
      context,
      title: 'Excluir Cliente',
      message: 'Tem certeza? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (ok == true && mounted) {
      final deleted = await context.read<ClienteController>().excluir(_cliente.id!);
      if (deleted && mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cliente.nome),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editar),
          if (_cliente.id != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _excluir,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(cliente: _cliente),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: StatCard(title: 'Atendimentos', value: '${_cliente.totalAtendimentos}', icon: Icons.cut)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(title: 'Total gasto', value: Fmt.currency(_cliente.totalGasto), icon: Icons.attach_money, color: AppColors.success)),
              ]),
              const SizedBox(height: 12),
              StatCard(
                title: 'Pontos fidelidade',
                value: Fmt.points(_cliente.pontosFidelidade),
                icon: Icons.star_outline,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              Text('Histórico de atendimentos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<AtendimentoController>(
                builder: (_, ctrl, __) {
                  if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
                  if (ctrl.atendimentos.isEmpty) {
                    return const DsEmptyState(message: 'Nenhum atendimento registrado.', icon: Icons.cut_outlined);
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.atendimentos.length,
                    itemBuilder: (_, i) => _AtendimentoTile(ctrl.atendimentos[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Cliente cliente;
  const _ProfileCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(cliente.nome[0].toUpperCase(), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(cliente.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  if (cliente.isAssinante) const AssinanteBadge(),
                ]),
                const SizedBox(height: 4),
                Text(cliente.telefone),
                if (cliente.email != null && cliente.email!.isNotEmpty) Text(cliente.email!, style: Theme.of(context).textTheme.bodySmall),
                if (cliente.dataNascimento != null)
                  Row(children: [
                    if (cliente.fazAniversarioHoje) const Icon(Icons.cake, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(Fmt.date(cliente.dataNascimento), style: Theme.of(context).textTheme.bodySmall),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtendimentoTile extends StatelessWidget {
  final Atendimento atendimento;
  const _AtendimentoTile(this.atendimento);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.cut, color: AppColors.primary, size: 18),
      ),
      title: Text(Fmt.dateTime(atendimento.dataHora)),
      subtitle: Text(atendimento.formaPagamento),
      trailing: Text(Fmt.currency(atendimento.total), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
