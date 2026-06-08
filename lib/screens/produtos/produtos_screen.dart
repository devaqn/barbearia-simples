import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/produto_controller.dart';
import '../../models/produto.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProdutoController>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProdutoController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
          if (ctrl.alertasEstoque.isNotEmpty)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${ctrl.alertasEstoque.length} produto(s) com estoque baixo!'),
                  backgroundColor: AppColors.warning,
                  action: SnackBarAction(label: 'Ver', textColor: Colors.white, onPressed: () {}),
                ));
              }
            });
          if (ctrl.produtos.isEmpty) {
            return DsEmptyState(
              message: 'Nenhum produto cadastrado.',
              icon: Icons.inventory_2_outlined,
              onAction: () => _showForm(context),
            );
          }
          return ListView.builder(
            itemCount: ctrl.produtos.length,
            itemBuilder: (_, i) => _ProdutoTile(ctrl.produtos[i], onEdit: () => _showForm(context, produto: ctrl.produtos[i])),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, {Produto? produto}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProdutoForm(produto: produto),
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  final Produto produto;
  final VoidCallback onEdit;

  const _ProdutoTile(this.produto, {required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: produto.abaixoDoMinimo ? AppColors.warning.withOpacity(0.15) : null,
        child: Icon(
          Icons.inventory_2,
          color: produto.abaixoDoMinimo ? AppColors.warning : null,
        ),
      ),
      title: Text(produto.nome),
      subtitle: Text('Estoque: ${produto.quantidade} ${produto.abaixoDoMinimo ? "⚠️" : ""}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Fmt.currency(produto.precoVenda), style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
        ],
      ),
    );
  }
}

class _ProdutoForm extends StatefulWidget {
  final Produto? produto;
  const _ProdutoForm({this.produto});

  @override
  State<_ProdutoForm> createState() => _ProdutoFormState();
}

class _ProdutoFormState extends State<_ProdutoForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome, _preco, _custo, _qtd, _min, _comissao;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.produto?.nome);
    _preco = TextEditingController(text: widget.produto?.precoVenda.toStringAsFixed(2));
    _custo = TextEditingController(text: widget.produto?.precoCusto.toStringAsFixed(2));
    _qtd = TextEditingController(text: '${widget.produto?.quantidade ?? 0}');
    _min = TextEditingController(text: '${widget.produto?.estoqueMinimo ?? 5}');
    _comissao = TextEditingController(text: '${widget.produto?.comissaoPercentual ?? 0}');
  }

  @override
  void dispose() {
    for (final c in [_nome, _preco, _custo, _qtd, _min, _comissao]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionManager>();
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DsTextField(controller: _nome, label: 'Nome', validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DsTextField(controller: _preco, label: 'Preço Venda', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 12),
                Expanded(child: DsTextField(controller: _custo, label: 'Preço Custo', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DsTextField(controller: _qtd, label: 'Quantidade', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: DsTextField(controller: _min, label: 'Estoque Mín.', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              DsTextField(controller: _comissao, label: 'Comissão (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final ctrl = context.read<ProdutoController>();
                  final p = Produto(
                    id: widget.produto?.id,
                    nome: _nome.text.trim(),
                    precoVenda: double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0,
                    precoCusto: double.tryParse(_custo.text.replaceAll(',', '.')) ?? 0,
                    quantidade: int.tryParse(_qtd.text) ?? 0,
                    estoqueMinimo: int.tryParse(_min.text) ?? 5,
                    comissaoPercentual: double.tryParse(_comissao.text.replaceAll(',', '.')) ?? 0,
                    barbeariaId: session.barbeariaId,
                    firebaseId: widget.produto?.firebaseId,
                  );
                  final ok = await ctrl.salvar(p);
                  if (ok && context.mounted) {
                    Navigator.pop(context);
                    UiHelpers.showSuccess(context, 'Produto salvo!');
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
