import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/financeiro_controller.dart';
import '../../models/despesa.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/ui_helpers.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<FinanceiroController>();
      ctrl.carregarResumo();
      ctrl.carregarDespesas();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Resumo'), Tab(text: 'Despesas')],
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<FinanceiroController>(
        builder: (context, ctrl, _) => TabBarView(
          controller: _tabs,
          children: [
            _ResumoTab(ctrl),
            _DespesasTab(ctrl),
          ],
        ),
      ),
    );
  }
}

class _ResumoTab extends StatelessWidget {
  final FinanceiroController ctrl;
  const _ResumoTab(this.ctrl);

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
    final fat = (ctrl.resumo['faturamento'] as num?)?.toDouble() ?? 0;
    final desp = (ctrl.resumo['despesas'] as num?)?.toDouble() ?? 0;
    final lucro = (ctrl.resumo['lucro'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: StatCard(title: 'Faturamento', value: Fmt.currency(fat), icon: Icons.trending_up, color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(title: 'Despesas', value: Fmt.currency(desp), icon: Icons.trending_down, color: AppColors.error)),
          ]),
          const SizedBox(height: 12),
          StatCard(title: 'Lucro Líquido', value: Fmt.currency(lucro), icon: Icons.account_balance, color: lucro >= 0 ? AppColors.success : AppColors.error),
          const SizedBox(height: 20),
          if (ctrl.faturamentoDiario.isNotEmpty) ...[
            Text('Faturamento por dia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: ctrl.faturamentoDiario.asMap().entries.map((e) {
                    final val = (e.value['valor'] as num?)?.toDouble() ?? 0;
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: val, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4)),
                    ]);
                  }).toList(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DespesasTab extends StatelessWidget {
  final FinanceiroController ctrl;
  const _DespesasTab(this.ctrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ctrl.despesas.isEmpty
              ? DsEmptyState(
                  message: 'Nenhuma despesa cadastrada.',
                  icon: Icons.money_off,
                  onAction: () => _showForm(context),
                )
              : ListView.builder(
                  itemCount: ctrl.despesas.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.money_off, size: 18)),
                    title: Text(ctrl.despesas[i].descricao),
                    subtitle: Text('${ctrl.despesas[i].categoria} · ${Fmt.date(ctrl.despesas[i].data)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Fmt.currency(ctrl.despesas[i].valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final ok = await UiHelpers.showConfirmDialog(
                              context, title: 'Excluir', message: 'Excluir esta despesa?', destructive: true);
                            if (ok == true) ctrl.excluirDespesa(ctrl.despesas[i].id!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DespesaForm(),
    );
  }
}

class _DespesaForm extends StatefulWidget {
  @override
  State<_DespesaForm> createState() => _DespesaFormState();
}

class _DespesaFormState extends State<_DespesaForm> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _valor = TextEditingController();
  String _categoria = Despesa.categorias.first;
  DateTime _data = DateTime.now();

  @override
  void dispose() { _desc.dispose(); _valor.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionManager>();
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova Despesa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DsTextField(controller: _desc, label: 'Descrição', validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoria,
              items: Despesa.categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoria = v!),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            DsTextField(controller: _valor, label: 'Valor (R\$)', keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse(v!.replaceAll(',', '.')) ?? 0) <= 0 ? 'Valor inválido' : null),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final ctrl = context.read<FinanceiroController>();
                final d = Despesa(
                  descricao: _desc.text.trim(),
                  categoria: _categoria,
                  valor: double.parse(_valor.text.replaceAll(',', '.')),
                  data: _data,
                  barbeariaId: session.barbeariaId,
                );
                final ok = await ctrl.salvarDespesa(d);
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  UiHelpers.showSuccess(context, 'Despesa salva!');
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
