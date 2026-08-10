import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/avaliacao.dart';
import '../../services/avaliacao_service.dart';
import '../../services/session_manager.dart';
import '../../database/database_helper.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';

class AvaliacoesScreen extends StatefulWidget {
  const AvaliacoesScreen({super.key});

  @override
  State<AvaliacoesScreen> createState() => _AvaliacoesScreenState();
}

class _AvaliacoesScreenState extends State<AvaliacoesScreen> {
  bool _loading = true;
  List<Avaliacao> _avaliacoes = [];
  Map<int, String> _barbeirosNomes = {};
  Map<int, String> _clientesNomes = {};
  Map<int, double> _medias = {};
  int? _filtroBarber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final session = context.read<SessionManager>();
      final svc = context.read<AvaliacaoService>();
      final db = context.read<DatabaseHelper>();
      final barbeariaId = session.barbeariaId;

      final avaliacoes = _filtroBarber != null
          ? await svc.listarPorBarbeiro(barbeariaId, _filtroBarber!)
          : await svc.listarPorBarbearia(barbeariaId);

      final medias = await svc.mediasPorBarbearia(barbeariaId);

      // Load barber and client names
      final barbeiros = await db.query('usuarios',
          where: 'barbearia_id = ?', whereArgs: [barbeariaId]);
      final nomesBarbeiros = <int, String>{};
      for (final b in barbeiros) {
        nomesBarbeiros[b['id'] as int] = b['nome'] as String;
      }

      final clientes = await db.query('clientes',
          where: 'barbearia_id = ?', whereArgs: [barbeariaId]);
      final nomesClientes = <int, String>{};
      for (final c in clientes) {
        nomesClientes[c['id'] as int] = c['nome'] as String;
      }

      if (mounted) {
        setState(() {
          _avaliacoes = avaliacoes;
          _barbeirosNomes = nomesBarbeiros;
          _clientesNomes = nomesClientes;
          _medias = medias;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar avaliações: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliações'),
        actions: [
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por barbeiro',
            onSelected: (value) {
              setState(() => _filtroBarber = value);
              _carregar();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              ..._barbeirosNomes.entries.map(
                (e) => PopupMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _avaliacoes.isEmpty
              ? const DsEmptyState(
                  message: 'Nenhuma avaliação encontrada.',
                  icon: Icons.star_outline,
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMediasCard(),
                      const SizedBox(height: 16),
                      ..._avaliacoes.map(_buildAvaliacaoCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMediasCard() {
    final entries = _filtroBarber != null
        ? _medias.entries.where((e) => e.key == _filtroBarber)
        : _medias.entries;

    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.darkCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Média de Avaliações',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _barbeirosNomes[e.key] ?? 'Barbeiro #${e.key}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _buildStars(e.value),
                      const SizedBox(width: 8),
                      Text(
                        e.value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAvaliacaoCard(Avaliacao a) {
    return Card(
      color: AppColors.darkCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    (_clientesNomes[a.clienteId] ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clientesNomes[a.clienteId] ?? 'Cliente #${a.clienteId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Barbeiro: ${_barbeirosNomes[a.barbeiroId] ?? '#${a.barbeiroId}'}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                _buildStars(a.nota.toDouble()),
              ],
            ),
            if (a.comentario != null && a.comentario!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                a.comentario!,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (a.criadoEm != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(a.criadoEm!),
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, size: 16, color: AppColors.gold);
        } else if (i < rating.ceil() && rating % 1 >= 0.5) {
          return Icon(Icons.star_half, size: 16, color: AppColors.gold);
        } else {
          return Icon(Icons.star_border, size: 16, color: AppColors.gold);
        }
      }),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
