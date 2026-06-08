import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/servico_controller.dart';
import '../../models/servico.dart';
import '../../services/session_manager.dart';
import '../../utils/security_utils.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class ServicoFormScreen extends StatefulWidget {
  const ServicoFormScreen({super.key});

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  final _duracao = TextEditingController(text: '30');
  final _comissao = TextEditingController(text: '50');
  Servico? _editing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is Servico) {
        _editing = arg;
        _nome.text = arg.nome;
        _descricao.text = arg.descricao ?? '';
        _preco.text = arg.preco.toStringAsFixed(2).replaceAll('.', ',');
        _duracao.text = '${arg.duracaoMinutos}';
        _comissao.text = arg.comissaoPercentual.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _preco.dispose();
    _duracao.dispose();
    _comissao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final session = context.read<SessionManager>();
    final ctrl = context.read<ServicoController>();

    final servico = Servico(
      id: _editing?.id,
      nome: SecurityUtils.sanitizeName(_nome.text.trim()),
      descricao: _descricao.text.trim().isNotEmpty ? _descricao.text.trim() : null,
      preco: double.parse(_preco.text.replaceAll(',', '.')),
      duracaoMinutos: int.tryParse(_duracao.text) ?? 30,
      comissaoPercentual: double.tryParse(_comissao.text) ?? 50.0,
      ativo: _editing?.ativo ?? true,
      barbeariaId: _editing?.barbeariaId ?? session.barbeariaId,
      firebaseId: _editing?.firebaseId,
    );

    final ok = await ctrl.salvar(servico);
    if (ok && mounted) {
      UiHelpers.showSuccess(context, _editing == null ? 'Serviço cadastrado!' : 'Serviço atualizado!');
      Navigator.pop(context, true);
    } else if (ctrl.errorMsg != null && mounted) {
      UiHelpers.showError(context, ctrl.errorMsg!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing == null ? 'Novo Serviço' : 'Editar Serviço')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsTextField(
                controller: _nome,
                label: 'Nome do serviço',
                prefixIcon: Icons.cut_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DsTextField(
                controller: _descricao,
                label: 'Descrição (opcional)',
                prefixIcon: Icons.notes,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DsTextField(
                controller: _preco,
                label: 'Preço (R\$)',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0;
                  return n <= 0 ? 'Preço deve ser maior que zero' : null;
                },
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: DsTextField(
                    controller: _duracao,
                    label: 'Duração (min)',
                    prefixIcon: Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '') ?? 0;
                      return n <= 0 ? 'Inválido' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DsTextField(
                    controller: _comissao,
                    label: 'Comissão (%)',
                    prefixIcon: Icons.percent,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '') ?? -1;
                      return n < 0 || n > 100 ? 'Inválido' : null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 28),
              Consumer<ServicoController>(
                builder: (_, ctrl, __) => ElevatedButton(
                  onPressed: ctrl.isLoading ? null : _salvar,
                  child: ctrl.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_editing == null ? 'Cadastrar' : 'Salvar alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
