import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/financeiro_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';

enum _Periodo { semana, mes, trimestre }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Periodo _periodo = _Periodo.mes;
  Map<String, dynamic> _resumo = {};
  List<Map<String, dynamic>> _porDia = [];
  List<Map<String, dynamic>> _porPagto = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  (DateTime, DateTime) get _range {
    final fim = DateTime.now();
    final inicio = switch (_periodo) {
      _Periodo.semana => fim.subtract(const Duration(days: 7)),
      _Periodo.mes => DateTime(fim.year, fim.month, 1),
      _Periodo.trimestre => fim.subtract(const Duration(days: 90)),
    };
    return (inicio, fim);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = context.read<SessionManager>();
      final svc = context.read<FinanceiroService>();
      final (inicio, fim) = _range;
      _resumo = await svc.resumo(barbeariaId: session.barbeariaId, inicio: inicio, fim: fim);
      _porDia = await svc.faturamentoPorDia(barbeariaId: session.barbeariaId, inicio: inicio, fim: fim);
      _porPagto = await svc.faturamentoPorFormaPagamento(barbeariaId: session.barbeariaId, inicio: inicio, fim: fim);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _PeriodoSelector(selected: _periodo, onChanged: (p) { setState(() => _periodo = p); _load(); }),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KpiCards(resumo: _resumo),
                          const SizedBox(height: 20),
                          if (_porDia.isNotEmpty) ...[
                            Text('Faturamento por dia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _BarChartWidget(data: _porDia),
                            const SizedBox(height: 20),
                          ],
                          if (_porPagto.isNotEmpty) ...[
                            Text('Por forma de pagamento', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _PagtoList(data: _porPagto),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodoSelector extends StatelessWidget {
  final _Periodo selected;
  final ValueChanged<_Periodo> onChanged;
  const _PeriodoSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(children: [
        for (final p in _Periodo.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_label(p)),
                selected: selected == p,
                onSelected: (_) => onChanged(p),
              ),
            ),
          ),
      ]),
    );
  }

  String _label(_Periodo p) => switch (p) {
    _Periodo.semana => 'Semana',
    _Periodo.mes => 'Mês',
    _Periodo.trimestre => 'Trimestre',
  };
}

class _KpiCards extends StatelessWidget {
  final Map<String, dynamic> resumo;
  const _KpiCards({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final fat = (resumo['faturamento'] as num?)?.toDouble() ?? 0.0;
    final desp = (resumo['despesas'] as num?)?.toDouble() ?? 0.0;
    final lucro = (resumo['lucro'] as num?)?.toDouble() ?? 0.0;
    final atend = (resumo['total_atendimentos'] as int?) ?? 0;
    return Column(children: [
      Row(children: [
        Expanded(child: StatCard(title: 'Faturamento', value: Fmt.currency(fat), icon: Icons.trending_up, color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(title: 'Despesas', value: Fmt.currency(desp), icon: Icons.trending_down, color: AppColors.error)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: StatCard(title: 'Lucro', value: Fmt.currency(lucro), icon: Icons.account_balance, color: lucro >= 0 ? AppColors.success : AppColors.error)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(title: 'Atendimentos', value: '$atend', icon: Icons.cut)),
      ]),
    ]);
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((e) => (e['valor'] as num?)?.toDouble() ?? 0.0).fold(0.0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barGroups: data.asMap().entries.map((e) {
            final val = (e.value['valor'] as num?)?.toDouble() ?? 0.0;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(toY: val, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4)),
            ]);
          }).toList(),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}

class _PagtoList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _PagtoList({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data.map((e) {
        final label = e['forma_pagamento'] as String? ?? '';
        final valor = (e['valor'] as num?)?.toDouble() ?? 0.0;
        final qtd = (e['quantidade'] as int?) ?? 0;
        return ListTile(
          dense: true,
          leading: const Icon(Icons.payment, size: 18),
          title: Text(label),
          subtitle: Text('$qtd pagamento(s)'),
          trailing: Text(Fmt.currency(valor), style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}
