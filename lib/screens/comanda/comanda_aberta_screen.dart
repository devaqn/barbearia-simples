import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/comanda_controller.dart';
import '../../controllers/servico_controller.dart';
import '../../controllers/produto_controller.dart';
import '../../models/item_comanda.dart';
import '../../models/servico.dart';
import '../../models/produto.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class ComandaAbertaScreen extends StatelessWidget {
  const ComandaAbertaScreen({super.key});

  static const _pagamentos = ['Dinheiro', 'PIX', 'Crédito', 'Débito'];

  @override
  Widget build(BuildContext context) {
    return Consumer<ComandaController>(
      builder: (context, ctrl, _) {
        final comanda = ctrl.comandaAtiva;
        if (comanda == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Comanda')),
            body: const DsEmptyState(message: 'Nenhuma comanda ativa.'),
          );
        }

        final isAberta = comanda.isAberta;

        return Scaffold(
          appBar: AppBar(
            title: Text('Comanda #${comanda.id}'),
            actions: [
              if (isAberta)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'cancelar') {
                      final ok = await UiHelpers.showConfirmDialog(
                        context,
                        title: 'Cancelar Comanda',
                        message: 'Deseja cancelar esta comanda?',
                        confirmLabel: 'Cancelar Comanda',
                        destructive: true,
                      );
                      if (ok == true) {
                        final done = await ctrl.cancelar();
                        if (done && context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'cancelar', child: Text('Cancelar Comanda')),
                  ],
                ),
            ],
          ),
          body: DsLoadingOverlay(
            isLoading: ctrl.isLoading,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (ctrl.errorMsg != null)
                        DsErrorBanner(message: ctrl.errorMsg!, onDismiss: ctrl.clearError),
                      ...comanda.itens.map((item) => _ItemTile(
                            item: item,
                            canRemove: isAberta,
                            onRemove: () => ctrl.removerItem(item.id!),
                          )),
                      if (comanda.itens.isEmpty)
                        const DsEmptyState(
                          message: 'Nenhum item adicionado.',
                          icon: Icons.playlist_add,
                        ),
                    ],
                  ),
                ),
                if (isAberta) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.design_services_outlined),
                            label: const Text('Serviço'),
                            onPressed: () => _addServico(context, ctrl),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text('Produto'),
                            onPressed: () => _addProduto(context, ctrl),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Serviços', style: Theme.of(context).textTheme.bodyMedium),
                          Text(Fmt.currency(comanda.totalServicos)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Produtos', style: Theme.of(context).textTheme.bodyMedium),
                          Text(Fmt.currency(comanda.totalProdutos)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(Fmt.currency(comanda.total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                        ],
                      ),
                      if (isAberta) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Fechar Comanda'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: AppColors.success,
                          ),
                          onPressed: () => _fechar(context, ctrl),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addServico(BuildContext context, ComandaController ctrl) async {
    final svc = context.read<ServicoController>();
    await svc.carregar();

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Servico>(
      context: context,
      builder: (_) => _ServicoPickerSheet(svc.servicos),
    );

    if (selected != null) {
      ctrl.adicionarItem(ItemComanda(
        comandaId: ctrl.comandaAtiva!.id!,
        tipo: 'servico',
        referenciaId: selected.id!,
        descricao: selected.nome,
        precoUnitario: selected.preco,
        comissaoPercentual: selected.comissaoPercentual,
      ));
    }
  }

  void _addProduto(BuildContext context, ComandaController ctrl) async {
    final pCtrl = context.read<ProdutoController>();
    await pCtrl.carregar();

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Produto>(
      context: context,
      builder: (_) => _ProdutoPickerSheet(pCtrl.produtos),
    );

    if (selected != null) {
      ctrl.adicionarItem(ItemComanda(
        comandaId: ctrl.comandaAtiva!.id!,
        tipo: 'produto',
        referenciaId: selected.id!,
        descricao: selected.nome,
        precoUnitario: selected.precoVenda,
        comissaoPercentual: selected.comissaoPercentual,
      ));
    }
  }

  void _fechar(BuildContext context, ComandaController ctrl) async {
    String? forma;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forma de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _pagamentos
              .map((p) => ListTile(
                    title: Text(p),
                    onTap: () {
                      forma = p;
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );

    if (forma != null && context.mounted) {
      final ok = await ctrl.fechar(forma!);
      if (ok && context.mounted) {
        UiHelpers.showSuccess(context, 'Comanda fechada com sucesso!');
        Navigator.pop(context);
      }
    }
  }
}

class _ItemTile extends StatelessWidget {
  final ItemComanda item;
  final bool canRemove;
  final VoidCallback onRemove;

  const _ItemTile({required this.item, required this.canRemove, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          item.tipo == 'servico' ? Icons.design_services : Icons.inventory_2,
          color: item.tipo == 'servico' ? AppColors.primary : AppColors.info,
        ),
        title: Text(item.descricao),
        subtitle: Text('${item.quantidade}x ${Fmt.currency(item.precoUnitario)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Fmt.currency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class _ServicoPickerSheet extends StatelessWidget {
  final List<Servico> servicos;

  const _ServicoPickerSheet(this.servicos);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Selecionar Serviço', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: servicos.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(servicos[i].nome),
              trailing: Text(Fmt.currency(servicos[i].preco), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(Fmt.duration(servicos[i].duracaoMinutos)),
              onTap: () => Navigator.pop(context, servicos[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProdutoPickerSheet extends StatelessWidget {
  final List<Produto> produtos;

  const _ProdutoPickerSheet(this.produtos);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Selecionar Produto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (_, i) {
              final p = produtos[i];
              return ListTile(
                title: Text(p.nome),
                subtitle: Text('Estoque: ${p.quantidade}'),
                trailing: Text(Fmt.currency(p.precoVenda), style: const TextStyle(fontWeight: FontWeight.bold)),
                enabled: p.quantidade > 0,
                onTap: p.quantidade > 0 ? () => Navigator.pop(context, p) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
