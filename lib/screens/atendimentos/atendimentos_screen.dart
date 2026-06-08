import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/atendimento_controller.dart';
import '../../models/atendimento.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';

class AtendimentosScreen extends StatefulWidget {
  const AtendimentosScreen({super.key});

  @override
  State<AtendimentosScreen> createState() => _AtendimentosScreenState();
}

class _AtendimentosScreenState extends State<AtendimentosScreen> {
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fim = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AtendimentoController>().carregar(inicio: _inicio, fim: _fim);
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _inicio, end: _fim),
      locale: const Locale('pt', 'BR'),
    );
    if (range != null) {
      setState(() {
        _inicio = range.start;
        _fim = range.end;
      });
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange, tooltip: 'Filtrar período'),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _PeriodoBanner(inicio: _inicio, fim: _fim, onTap: _pickRange),
          Expanded(
            child: Consumer<AtendimentoController>(
              builder: (_, ctrl, __) {
                if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
                if (ctrl.atendimentos.isEmpty) {
                  return const DsEmptyState(message: 'Nenhum atendimento neste período.', icon: Icons.cut_outlined);
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: ctrl.atendimentos.length,
                    itemBuilder: (_, i) => _AtendimentoTile(ctrl.atendimentos[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodoBanner extends StatelessWidget {
  final DateTime inicio;
  final DateTime fim;
  final VoidCallback onTap;
  const _PeriodoBanner({required this.inicio, required this.fim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(children: [
          const Icon(Icons.date_range, size: 16),
          const SizedBox(width: 8),
          Text('${Fmt.date(inicio)} – ${Fmt.date(fim)}'),
          const Spacer(),
          const Icon(Icons.edit, size: 14),
        ]),
      ),
    );
  }
}

class _AtendimentoTile extends StatelessWidget {
  final Atendimento atendimento;
  const _AtendimentoTile(this.atendimento);

  String _pagtoLabel(String fp) {
    switch (fp) {
      case 'dinheiro': return 'Dinheiro';
      case 'pix': return 'PIX';
      case 'cartao_credito': return 'Cartão Crédito';
      case 'cartao_debito': return 'Cartão Débito';
      default: return fp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.cut, color: AppColors.primary, size: 18),
      ),
      title: Text(Fmt.dateTime(atendimento.dataHora)),
      subtitle: Row(children: [
        const Icon(Icons.payment, size: 12),
        const SizedBox(width: 4),
        Text(_pagtoLabel(atendimento.formaPagamento), style: Theme.of(context).textTheme.bodySmall),
        if (atendimento.itens.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('· ${atendimento.itens.length} item(ns)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ]),
      trailing: Text(Fmt.currency(atendimento.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      onTap: atendimento.itens.isNotEmpty ? () => _showItens(context, atendimento) : null,
    );
  }

  void _showItens(BuildContext context, Atendimento at) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Itens do atendimento', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...at.itens.map((item) => ListTile(
              dense: true,
              title: Text(item.descricao),
              subtitle: Text('${item.quantidade}x ${Fmt.currency(item.precoUnitario)}'),
              trailing: Text(Fmt.currency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }
}
