import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente.dart';
import '../../utils/formatters.dart';
import '../../utils/app_routes.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/assinante_badge.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteController>().carregar();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.clienteForm),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou telefone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          context.read<ClienteController>().carregar();
                        },
                      )
                    : null,
              ),
              onChanged: (v) => context.read<ClienteController>().carregar(busca: v),
            ),
          ),
          Expanded(
            child: Consumer<ClienteController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.clientes.isEmpty) {
                  return DsEmptyState(
                    message: 'Nenhum cliente encontrado.',
                    icon: Icons.people_outline,
                    onAction: () => Navigator.pushNamed(context, AppRoutes.clienteForm),
                    actionLabel: 'Adicionar Cliente',
                  );
                }
                return ListView.builder(
                  itemCount: ctrl.clientes.length,
                  itemBuilder: (_, i) => _ClienteTile(ctrl.clientes[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteTile extends StatelessWidget {
  final Cliente cliente;

  const _ClienteTile(this.cliente);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(cliente.nome[0].toUpperCase()),
      ),
      title: Row(
        children: [
          Expanded(child: Text(cliente.nome)),
          if (cliente.isAssinante) const AssinanteBadge(mini: true),
          if (cliente.fazAniversarioHoje)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.cake, size: 16, color: Colors.orange),
            ),
        ],
      ),
      subtitle: Text(cliente.telefone),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Fmt.currency(cliente.totalGasto), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('${cliente.totalAtendimentos} atend.', style: const TextStyle(fontSize: 11)),
        ],
      ),
      onTap: () => Navigator.pushNamed(context, AppRoutes.clienteDetalhe, arguments: cliente),
    );
  }
}
