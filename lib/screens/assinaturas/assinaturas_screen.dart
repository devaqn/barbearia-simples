import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/assinatura.dart';
import '../../models/cliente.dart';
import '../../services/assinatura_service.dart';
import '../../services/cliente_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/ui_helpers.dart';

class AssinaturasScreen extends StatefulWidget {
  const AssinaturasScreen({super.key});

  @override
  State<AssinaturasScreen> createState() => _AssinaturasScreenState();
}

class _AssinaturasScreenState extends State<AssinaturasScreen> {
  List<Assinatura> _assinaturas = [];
  Map<String, dynamic> _kpis = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = context.read<SessionManager>();
      final svc = context.read<AssinaturaService>();
      _assinaturas = await svc.listar(session.barbeariaId);
      _kpis = await svc.kpis(session.barbeariaId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assinaturas')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNovaAssinatura(context),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _KpiRow(kpis: _kpis),
                    const SizedBox(height: 20),
                    if (_assinaturas.isEmpty)
                      DsEmptyState(
                        message: 'Nenhuma assinatura cadastrada.',
                        icon: Icons.card_membership_outlined,
                        onAction: () => _showNovaAssinatura(context),
                        actionLabel: 'Nova Assinatura',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assinaturas.length,
                        itemBuilder: (_, i) => _AssinaturaTile(
                          assinatura: _assinaturas[i],
                          onCancelar: () async {
                            final ok = await UiHelpers.showConfirmDialog(
                              context, title: 'Cancelar Assinatura', message: 'Confirmar cancelamento?',
                              confirmLabel: 'Cancelar', destructive: true,
                            );
                            if (ok == true) {
                              await context.read<AssinaturaService>().cancelar(_assinaturas[i].id!);
                              await _load();
                            }
                          },
                          onCheckout: () => _abrirCheckout(context, _assinaturas[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showNovaAssinatura(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NovaAssinaturaForm(),
    ).then((_) => _load());
  }

  void _abrirCheckout(BuildContext context, Assinatura assinatura) {
    // Only show WebView if there's a Mercado Pago subscription ID / URL
    if (assinatura.mpSubscriptionId == null) {
      UiHelpers.showError(context, 'Checkout MP não disponível. Configure o ID do plano MP.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MercadoPagoWebView(
          url: 'https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=${assinatura.mpSubscriptionId}',
          title: 'Checkout MP',
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final Map<String, dynamic> kpis;
  const _KpiRow({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final total = (kpis['total_ativas'] as int?) ?? 0;
    final mrr = (kpis['mrr'] as num?)?.toDouble() ?? 0.0;
    final vencendo = (kpis['vencendo_em_7_dias'] as int?) ?? 0;
    return Column(children: [
      Row(children: [
        Expanded(child: StatCard(title: 'Ativas', value: '$total', icon: Icons.check_circle_outline, color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(title: 'MRR', value: Fmt.currency(mrr), icon: Icons.attach_money, color: AppColors.primary)),
      ]),
      const SizedBox(height: 12),
      if (vencendo > 0)
        StatCard(title: 'Vencendo em 7 dias', value: '$vencendo', icon: Icons.warning_amber_outlined, color: Colors.orange),
    ]);
  }
}

class _AssinaturaTile extends StatelessWidget {
  final Assinatura assinatura;
  final VoidCallback onCancelar;
  final VoidCallback onCheckout;
  const _AssinaturaTile({required this.assinatura, required this.onCancelar, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final color = assinatura.estaEmDia ? AppColors.success : AppColors.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.card_membership, color: color, size: 20),
        ),
        title: Text('Plano: ${assinatura.plano}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vencimento: ${Fmt.date(assinatura.dataVencimento)}'),
            Text(assinatura.status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.currency(assinatura.valor), style: const TextStyle(fontWeight: FontWeight.bold)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cancelar') onCancelar();
                if (v == 'checkout') onCheckout();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'checkout', child: Text('Link de pagamento')),
                const PopupMenuItem(value: 'cancelar', child: Text('Cancelar', style: TextStyle(color: Colors.red))),
              ],
              child: const Icon(Icons.more_vert, size: 18),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _NovaAssinaturaForm extends StatefulWidget {
  @override
  State<_NovaAssinaturaForm> createState() => _NovaAssinaturaFormState();
}

class _NovaAssinaturaFormState extends State<_NovaAssinaturaForm> {
  final _form = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _plano = TextEditingController(text: 'Mensal');
  final _mpId = TextEditingController();
  Cliente? _cliente;
  List<Cliente> _clientes = [];
  bool _loadingClientes = true;
  DateTime _inicio = DateTime.now();
  DateTime _vencimento = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    final session = context.read<SessionManager>();
    final svc = context.read<ClienteService>();
    _clientes = await svc.listar(session.barbeariaId);
    if (mounted) setState(() => _loadingClientes = false);
  }

  @override
  void dispose() { _valor.dispose(); _plano.dispose(); _mpId.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionManager>();
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova Assinatura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _loadingClientes
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Cliente>(
                    value: _cliente,
                    hint: const Text('Selecionar cliente'),
                    items: _clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))).toList(),
                    onChanged: (v) => setState(() => _cliente = v),
                    validator: (v) => v == null ? 'Selecione um cliente' : null,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                  ),
            const SizedBox(height: 12),
            DsTextField(controller: _plano, label: 'Nome do plano', prefixIcon: Icons.card_membership_outlined,
              validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            DsTextField(controller: _valor, label: 'Valor (R\$)', prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Valor inválido' : null),
            const SizedBox(height: 12),
            DsTextField(controller: _mpId, label: 'ID Plano Mercado Pago (opcional)', prefixIcon: Icons.payment_outlined),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final svc = context.read<AssinaturaService>();
                final assinatura = Assinatura(
                  clienteId: _cliente!.id!,
                  plano: _plano.text.trim(),
                  status: 'ativo',
                  valor: double.parse(_valor.text.replaceAll(',', '.')),
                  dataInicio: _inicio,
                  dataVencimento: _vencimento,
                  mpSubscriptionId: _mpId.text.trim().isNotEmpty ? _mpId.text.trim() : null,
                  barbeariaId: session.barbeariaId,
                );
                try {
                  await svc.salvar(assinatura);
                  if (context.mounted) {
                    Navigator.pop(context);
                    UiHelpers.showSuccess(context, 'Assinatura criada!');
                  }
                } catch (e) {
                  if (context.mounted) UiHelpers.showError(context, e.toString());
                }
              },
              child: const Text('Criar Assinatura'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MercadoPagoWebView extends StatefulWidget {
  final String url;
  final String title;
  const _MercadoPagoWebView({required this.url, required this.title});

  @override
  State<_MercadoPagoWebView> createState() => _MercadoPagoWebViewState();
}

class _MercadoPagoWebViewState extends State<_MercadoPagoWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
