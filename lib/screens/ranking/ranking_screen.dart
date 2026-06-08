import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cliente_controller.dart';
import '../../models/cliente.dart';
import '../../services/financeiro_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _barbeiros = [];
  List<Cliente> _topClientes = [];
  bool _loading = true;
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fim = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = context.read<SessionManager>();
      final finSvc = context.read<FinanceiroService>();
      final clienteCtrl = context.read<ClienteController>();
      _barbeiros = await finSvc.rankingBarbeiros(
        barbeariaId: session.barbeariaId,
        inicio: _inicio,
        fim: _fim,
      );
      _topClientes = await clienteCtrl.rankingMelhores();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
      setState(() { _inicio = range.start; _fim = range.end; });
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Barbeiros'), Tab(text: 'Clientes')]),
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _barbeiros.isEmpty
                    ? const DsEmptyState(message: 'Sem dados neste período.', icon: Icons.emoji_events_outlined)
                    : ListView.builder(
                        itemCount: _barbeiros.length,
                        itemBuilder: (_, i) => _BarbeiroTile(rank: i + 1, data: _barbeiros[i]),
                      ),
                _topClientes.isEmpty
                    ? const DsEmptyState(message: 'Nenhum cliente.', icon: Icons.person_outlined)
                    : ListView.builder(
                        itemCount: _topClientes.length,
                        itemBuilder: (_, i) => _ClienteTile(rank: i + 1, cliente: _topClientes[i]),
                      ),
              ],
            ),
    );
  }
}

class _BarbeiroTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  const _BarbeiroTile({required this.rank, required this.data});

  Color get _rankColor {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.blueGrey;
    if (rank == 3) return Colors.brown;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final fat = (data['faturamento'] as num?)?.toDouble() ?? 0.0;
    final com = (data['comissao'] as num?)?.toDouble() ?? 0.0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _rankColor.withValues(alpha: 0.15),
        child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: _rankColor)),
      ),
      title: Text(data['nome'] as String? ?? 'Barbeiro', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Comissão: ${Fmt.currency(com)}'),
      trailing: Text(Fmt.currency(fat), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
    );
  }
}

class _ClienteTile extends StatelessWidget {
  final int rank;
  final Cliente cliente;
  const _ClienteTile({required this.rank, required this.cliente});

  Color get _rankColor {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.blueGrey;
    if (rank == 3) return Colors.brown;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _rankColor.withValues(alpha: 0.15),
        child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: _rankColor)),
      ),
      title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${cliente.totalAtendimentos} atendimentos'),
      trailing: Text(Fmt.currency(cliente.totalGasto), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
    );
  }
}
