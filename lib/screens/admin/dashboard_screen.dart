import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';
import '../../utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      final data = await svc.resumoAdmin(session.barbeariaId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
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
                    if ((_data['aniversariantes_hoje'] as int? ?? 0) > 0)
                      _AlertCard(
                        icon: Icons.cake_outlined,
                        message: '${_data['aniversariantes_hoje']} aniversariante(s) hoje!',
                        color: AppColors.gold,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.clientes),
                      ),
                    if ((_data['alertas_estoque'] as int? ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      _AlertCard(
                        icon: Icons.warning_amber_outlined,
                        message: '${_data['alertas_estoque']} produto(s) com estoque baixo.',
                        color: AppColors.warning,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.estoque),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Hoje', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Atendimentos',
                            value: '${_data['atendimentos_hoje'] ?? 0}',
                            icon: Icons.content_cut,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Faturamento',
                            value: Fmt.currency((_data['faturamento_hoje'] as num?)?.toDouble() ?? 0),
                            icon: Icons.attach_money,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Este mês', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Atendimentos',
                            value: '${_data['atendimentos_mes'] ?? 0}',
                            icon: Icons.content_cut,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Faturamento',
                            value: Fmt.currency((_data['faturamento_mes'] as num?)?.toDouble() ?? 0),
                            icon: Icons.trending_up,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Assinaturas Ativas',
                            value: '${_data['assinaturas_ativas'] ?? 0}',
                            icon: Icons.star,
                            color: AppColors.gold,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.assinaturas),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Semana',
                            value: Fmt.currency((_data['faturamento_semana'] as num?)?.toDouble() ?? 0),
                            icon: Icons.calendar_view_week,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _QuickActions(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback onTap;

  const _AlertCard({required this.icon, required this.message, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações Rápidas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickChip(Icons.receipt_long_outlined, 'Nova Comanda', AppRoutes.comandas, context),
            _QuickChip(Icons.person_add_outlined, 'Novo Cliente', AppRoutes.clientes, context),
            _QuickChip(Icons.calendar_month_outlined, 'Agendar', AppRoutes.agenda, context),
            _QuickChip(Icons.bar_chart_outlined, 'Relatórios', AppRoutes.relatorios, context),
          ],
        ),
      ],
    );
  }

  Widget _QuickChip(IconData icon, String label, String route, BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }
}
