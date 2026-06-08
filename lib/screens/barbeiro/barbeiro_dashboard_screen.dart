import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';

class BarbeiroDashboardScreen extends StatefulWidget {
  const BarbeiroDashboardScreen({super.key});

  @override
  State<BarbeiroDashboardScreen> createState() => _BarbeiroDashboardScreenState();
}

class _BarbeiroDashboardScreenState extends State<BarbeiroDashboardScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = context.read<SessionManager>();
      final svc = context.read<DashboardService>();
      final data = await svc.resumoBarbeiro(session.userId!, session.barbeariaId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${session.currentUser?.nome.split(' ').first ?? ''}!'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoje', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: StatCard(
                        title: 'Atendimentos',
                        value: '${_data['atendimentos_hoje'] ?? 0}',
                        icon: Icons.content_cut,
                        color: AppColors.primary,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(
                        title: 'Faturamento',
                        value: Fmt.currency((_data['faturamento_hoje'] as num?)?.toDouble() ?? 0),
                        icon: Icons.attach_money,
                        color: AppColors.success,
                      )),
                    ]),
                    const SizedBox(height: 20),
                    Text('Este mês', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: StatCard(
                        title: 'Atendimentos',
                        value: '${_data['atendimentos_mes'] ?? 0}',
                        icon: Icons.content_cut,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(
                        title: 'Comissão Pendente',
                        value: Fmt.currency((_data['comissao_pendente'] as num?)?.toDouble() ?? 0),
                        icon: Icons.payments_outlined,
                        color: AppColors.warning,
                      )),
                    ]),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Nova Comanda'),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.comandas),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Agenda'),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.agenda),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
    );
  }
}
