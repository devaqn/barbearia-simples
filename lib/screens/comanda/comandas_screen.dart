import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/comanda_controller.dart';
import '../../models/comanda.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';

class ComandasScreen extends StatefulWidget {
  const ComandasScreen({super.key});

  @override
  State<ComandasScreen> createState() => _ComandasScreenState();
}

class _ComandasScreenState extends State<ComandasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComandaController>().carregar();
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
        title: const Text('Comandas'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Abertas'),
            Tab(text: 'Fechadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novaComanda(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Comanda'),
      ),
      body: Consumer<ComandaController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());

          final abertas = ctrl.comandas.where((c) => c.status == 'aberta').toList();
          final fechadas = ctrl.comandas.where((c) => c.status == 'fechada').toList();
          final canceladas = ctrl.comandas.where((c) => c.status == 'cancelada').toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _ComandaList(abertas, emptyMsg: 'Nenhuma comanda aberta.'),
              _ComandaList(fechadas, emptyMsg: 'Nenhuma comanda fechada.'),
              _ComandaList(canceladas, emptyMsg: 'Nenhuma comanda cancelada.'),
            ],
          );
        },
      ),
    );
  }

  void _novaComanda() {
    final ctrl = context.read<ComandaController>();
    ctrl.abrir().then((ok) {
      if (ok && mounted) {
        Navigator.pushNamed(context, AppRoutes.comandaAberta);
      }
    });
  }
}

class _ComandaList extends StatelessWidget {
  final List<Comanda> comandas;
  final String emptyMsg;

  const _ComandaList(this.comandas, {required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (comandas.isEmpty) {
      return DsEmptyState(message: emptyMsg, icon: Icons.receipt_long_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: comandas.length,
      itemBuilder: (_, i) => _ComandaCard(comandas[i]),
    );
  }
}

class _ComandaCard extends StatelessWidget {
  final Comanda comanda;

  const _ComandaCard(this.comanda);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (comanda.status) {
      case 'aberta': statusColor = AppColors.warning; break;
      case 'fechada': statusColor = AppColors.success; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.receipt_long, color: statusColor, size: 20),
        ),
        title: Text('Comanda #${comanda.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(Fmt.dateTime(comanda.dataAbertura)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.currency(comanda.total), style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(comanda.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        onTap: () {
          context.read<ComandaController>().setComandaAtiva(comanda);
          Navigator.pushNamed(context, AppRoutes.comandaAberta);
        },
      ),
    );
  }
}
