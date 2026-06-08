import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/caixa.dart';
import '../../services/caixa_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/ui_helpers.dart';

class CaixaScreen extends StatefulWidget {
  const CaixaScreen({super.key});

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen> {
  Caixa? _caixaAberto;
  Map<String, dynamic> _totais = {};
  List<Caixa> _historico = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = context.read<SessionManager>();
      final svc = context.read<CaixaService>();
      _caixaAberto = await svc.buscarAberto(session.userId!, session.barbeariaId);
      if (_caixaAberto != null) {
        _totais = await svc.calcularTotais(_caixaAberto!.id!, session.barbeariaId);
      }
      _historico = await svc.listarHistorico(session.barbeariaId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _abrirCaixa() async {
    final saldoStr = await UiHelpers.showInputDialog(context, title: 'Saldo inicial', hint: 'Ex: 100,00', initialValue: '0');
    if (saldoStr == null) return;
    final saldo = double.tryParse(saldoStr.replaceAll(',', '.')) ?? 0.0;
    try {
      final session = context.read<SessionManager>();
      final svc = context.read<CaixaService>();
      await svc.abrirCaixa(barbeiroId: session.userId!, saldoInicial: saldo, barbeariaId: session.barbeariaId);
      UiHelpers.showSuccess(context, 'Caixa aberto!');
      await _load();
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e.toString());
    }
  }

  Future<void> _fecharCaixa() async {
    final ok = await UiHelpers.showConfirmDialog(context, title: 'Fechar Caixa', message: 'Confirmar fechamento do caixa?', confirmLabel: 'Fechar');
    if (ok != true) return;
    final svc = context.read<CaixaService>();
    try {
      final totFaturado = (_totais['total_faturado'] as num?)?.toDouble() ?? 0.0;
      final saldoFinal = (_caixaAberto!.saldoInicial) + totFaturado;
      final resumo = <String, double>{
        if ((_totais['dinheiro'] as num? ?? 0) > 0) 'Dinheiro': (_totais['dinheiro'] as num).toDouble(),
        if ((_totais['pix'] as num? ?? 0) > 0) 'PIX': (_totais['pix'] as num).toDouble(),
        if ((_totais['cartao_credito'] as num? ?? 0) > 0) 'Cartão Crédito': (_totais['cartao_credito'] as num).toDouble(),
        if ((_totais['cartao_debito'] as num? ?? 0) > 0) 'Cartão Débito': (_totais['cartao_debito'] as num).toDouble(),
      };
      await svc.fecharCaixa(_caixaAberto!.id!, saldoFinal, resumo);
      if (mounted) UiHelpers.showSuccess(context, 'Caixa fechado!');
      await _load();
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caixa')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _caixaAberto == null ? _CaixaFechada(onAbrir: _abrirCaixa, historico: _historico) : _CaixaAberta(caixa: _caixaAberto!, totais: _totais, onFechar: _fecharCaixa),
              ),
            ),
    );
  }
}

class _CaixaFechada extends StatelessWidget {
  final VoidCallback onAbrir;
  final List<Caixa> historico;
  const _CaixaFechada({required this.onAbrir, required this.historico});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DsCard(
          child: Column(
            children: [
              Icon(Icons.point_of_sale, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('Nenhum caixa aberto', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Abra o caixa para registrar movimentações.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onAbrir, icon: const Icon(Icons.play_arrow), label: const Text('Abrir Caixa'))),
            ],
          ),
        ),
        if (historico.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Histórico', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...historico.map((c) => _HistoricoTile(c)),
        ],
      ],
    );
  }
}

class _CaixaAberta extends StatelessWidget {
  final Caixa caixa;
  final Map<String, dynamic> totais;
  final VoidCallback onFechar;
  const _CaixaAberta({required this.caixa, required this.totais, required this.onFechar});

  @override
  Widget build(BuildContext context) {
    final totalFaturado = (totais['total_faturado'] as num?)?.toDouble() ?? 0.0;
    final totalComandas = (totais['total_comandas'] as num?)?.toInt() ?? 0;
    final dinheiro = (totais['dinheiro'] as num?)?.toDouble() ?? 0.0;
    final pix = (totais['pix'] as num?)?.toDouble() ?? 0.0;
    final credito = (totais['cartao_credito'] as num?)?.toDouble() ?? 0.0;
    final debito = (totais['cartao_debito'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DsCard(
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.success.withValues(alpha: 0.1), child: Icon(Icons.point_of_sale, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Caixa Aberto', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Aberto em: ${Fmt.dateTime(caixa.dataAbertura)}', style: Theme.of(context).textTheme.bodySmall),
                Text('Saldo inicial: ${Fmt.currency(caixa.saldoInicial)}', style: Theme.of(context).textTheme.bodySmall),
              ])),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatCard(title: 'Faturado', value: Fmt.currency(totalFaturado), icon: Icons.trending_up, color: AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(title: 'Comandas', value: '$totalComandas', icon: Icons.receipt_long)),
        ]),
        const SizedBox(height: 12),
        if (dinheiro > 0 || pix > 0 || credito > 0 || debito > 0) ...[
          Text('Por forma de pagamento', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (dinheiro > 0) _PagtoRow(label: 'Dinheiro', valor: dinheiro, icon: Icons.money),
          if (pix > 0) _PagtoRow(label: 'PIX', valor: pix, icon: Icons.pix),
          if (credito > 0) _PagtoRow(label: 'Cartão Crédito', valor: credito, icon: Icons.credit_card),
          if (debito > 0) _PagtoRow(label: 'Cartão Débito', valor: debito, icon: Icons.credit_card_outlined),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onFechar,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Fechar Caixa'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ),
      ],
    );
  }
}

class _PagtoRow extends StatelessWidget {
  final String label;
  final double valor;
  final IconData icon;
  const _PagtoRow({required this.label, required this.valor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(Fmt.currency(valor), style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _HistoricoTile extends StatelessWidget {
  final Caixa caixa;
  const _HistoricoTile(this.caixa);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.point_of_sale, size: 18)),
      title: Text('Caixa #${caixa.id}'),
      subtitle: Text(Fmt.date(caixa.dataAbertura)),
      trailing: caixa.saldoFinal != null ? Text(Fmt.currency(caixa.saldoFinal!), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
    );
  }
}
