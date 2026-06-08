import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/produto_controller.dart';
import '../../database/database_helper.dart';
import '../../models/movimento_estoque.dart';
import '../../models/produto.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<MovimentoEstoque> _movimentos = [];
  bool _loadingMovimentos = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoController>().carregar();
      _loadMovimentos();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadMovimentos() async {
    setState(() => _loadingMovimentos = true);
    try {
      final session = context.read<SessionManager>();
      final db = context.read<DatabaseHelper>();
      final rows = await db.rawQuery(
        '''SELECT me.*, p.nome as produto_nome
           FROM movimentos_estoque me
           LEFT JOIN produtos p ON p.id = me.produto_id
           WHERE me.barbearia_id = ?
           ORDER BY me.data_hora DESC LIMIT 50''',
        [session.barbeariaId],
      );
      _movimentos = rows.map(MovimentoEstoque.fromMap).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingMovimentos = false);
  }

  void _showEntradaDialog(BuildContext context, List<Produto> produtos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EntradaEstoqueForm(produtos: produtos),
    ).then((_) {
      context.read<ProdutoController>().carregar();
      _loadMovimentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Produtos'), Tab(text: 'Movimentos')],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabs,
        children: [
          Consumer<ProdutoController>(
            builder: (context, ctrl, _) {
              if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
              if (ctrl.produtos.isEmpty) {
                return const DsEmptyState(message: 'Nenhum produto cadastrado.', icon: Icons.inventory_2_outlined);
              }
              return RefreshIndicator(
                onRefresh: () => ctrl.carregar(),
                child: ListView.builder(
                  itemCount: ctrl.produtos.length,
                  itemBuilder: (_, i) {
                    final p = ctrl.produtos[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.abaixoDoMinimo ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                        child: Icon(
                          p.abaixoDoMinimo ? Icons.warning_amber : Icons.inventory_2,
                          color: p.abaixoDoMinimo ? AppColors.error : AppColors.success,
                          size: 20,
                        ),
                      ),
                      title: Text(p.nome),
                      subtitle: Text('Mínimo: ${p.estoqueMinimo} · Custo médio: ${Fmt.currency(p.custoMedio)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${p.quantidade} un', style: TextStyle(fontWeight: FontWeight.bold, color: p.abaixoDoMinimo ? AppColors.error : null)),
                          Text(Fmt.currency(p.precoVenda), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      onTap: () => _showEntradaDialog(context, ctrl.produtos),
                    );
                  },
                ),
              );
            },
          ),
          _loadingMovimentos
              ? const Center(child: CircularProgressIndicator())
              : _movimentos.isEmpty
                  ? const DsEmptyState(message: 'Nenhuma movimentação.', icon: Icons.swap_vert)
                  : ListView.builder(
                      itemCount: _movimentos.length,
                      itemBuilder: (_, i) => _MovimentoTile(_movimentos[i]),
                    ),
        ],
      ),
      floatingActionButton: Consumer<ProdutoController>(
        builder: (context, ctrl, _) => FloatingActionButton.extended(
          onPressed: ctrl.produtos.isEmpty ? null : () => _showEntradaDialog(context, ctrl.produtos),
          icon: const Icon(Icons.add),
          label: const Text('Entrada'),
        ),
      ),
    );
  }
}

class _MovimentoTile extends StatelessWidget {
  final MovimentoEstoque mov;
  const _MovimentoTile(this.mov);

  @override
  Widget build(BuildContext context) {
    final isEntrada = mov.tipo == 'entrada';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isEntrada ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        child: Icon(isEntrada ? Icons.arrow_downward : Icons.arrow_upward, color: isEntrada ? AppColors.success : AppColors.error, size: 18),
      ),
      title: Text('${mov.tipo.toUpperCase()} · ${mov.quantidade} un'),
      subtitle: Text('Prod. #${mov.produtoId} · ${Fmt.dateTime(mov.dataHora)}'),
      trailing: mov.custoUnitario > 0 ? Text(Fmt.currency(mov.custoUnitario * mov.quantidade)) : null,
    );
  }
}

class _EntradaEstoqueForm extends StatefulWidget {
  final List<Produto> produtos;
  const _EntradaEstoqueForm({required this.produtos});

  @override
  State<_EntradaEstoqueForm> createState() => _EntradaEstoqueFormState();
}

class _EntradaEstoqueFormState extends State<_EntradaEstoqueForm> {
  final _form = GlobalKey<FormState>();
  final _qtd = TextEditingController();
  final _custo = TextEditingController();
  final _obs = TextEditingController();
  Produto? _produto;

  @override
  void dispose() { _qtd.dispose(); _custo.dispose(); _obs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Entrada de Estoque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<Produto>(
              value: _produto,
              hint: const Text('Selecione o produto'),
              items: widget.produtos.map((p) => DropdownMenuItem(value: p, child: Text(p.nome))).toList(),
              onChanged: (v) => setState(() => _produto = v),
              validator: (v) => v == null ? 'Selecione um produto' : null,
              decoration: const InputDecoration(labelText: 'Produto'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DsTextField(controller: _qtd, label: 'Quantidade', keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Inválido' : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DsTextField(controller: _custo, label: 'Custo unit. (R\$)', keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? -1) < 0 ? 'Inválido' : null),
              ),
            ]),
            const SizedBox(height: 12),
            DsTextField(controller: _obs, label: 'Observações (opcional)', maxLines: 2),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final ctrl = context.read<ProdutoController>();
                final ok = await ctrl.entradaEstoque(
                  produtoId: _produto!.id!,
                  quantidade: int.parse(_qtd.text),
                  custo: double.tryParse(_custo.text.replaceAll(',', '.')) ?? 0.0,
                  obs: _obs.text.trim().isNotEmpty ? _obs.text.trim() : null,
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  UiHelpers.showSuccess(context, 'Entrada registrada!');
                } else if (ctrl.errorMsg != null && context.mounted) {
                  UiHelpers.showError(context, ctrl.errorMsg!);
                }
              },
              child: const Text('Registrar Entrada'),
            ),
          ],
        ),
      ),
    );
  }
}
