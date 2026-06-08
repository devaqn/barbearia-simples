import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/session_manager.dart';
import '../utils/app_routes.dart';
import '../utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final user = session.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (user?.nome.isNotEmpty == true) ? user!.nome[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user?.nome ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(context, Icons.dashboard_outlined, 'Dashboard',
                    session.isAdmin ? AppRoutes.dashboard : AppRoutes.barberDashboard),
                  _item(context, Icons.receipt_long_outlined, 'Comandas', AppRoutes.comandas),
                  _item(context, Icons.calendar_month_outlined, 'Agenda', AppRoutes.agenda),
                  _item(context, Icons.people_outlined, 'Clientes', AppRoutes.clientes),
                  if (session.isAdmin) ...[
                    const Divider(),
                    _item(context, Icons.design_services_outlined, 'Serviços', AppRoutes.servicos),
                    _item(context, Icons.inventory_2_outlined, 'Produtos', AppRoutes.produtos),
                    _item(context, Icons.warehouse_outlined, 'Estoque', AppRoutes.estoque),
                    _item(context, Icons.attach_money, 'Financeiro', AppRoutes.financeiro),
                    _item(context, Icons.point_of_sale_outlined, 'Caixa', AppRoutes.caixa),
                    _item(context, Icons.star_border, 'Assinaturas', AppRoutes.assinaturas),
                    _item(context, Icons.bar_chart_outlined, 'Relatórios', AppRoutes.relatorios),
                    _item(context, Icons.people_alt_outlined, 'Usuários', AppRoutes.adminUsuarios),
                  ],
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthController>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _item(BuildContext context, IconData icon, String label, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    final selected = current == route;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : null),
      title: Text(label),
      selected: selected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        if (!selected) Navigator.pushNamed(context, route);
      },
    );
  }
}
