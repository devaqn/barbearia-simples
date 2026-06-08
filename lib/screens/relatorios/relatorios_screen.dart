import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/atendimento_service.dart';
import '../../services/financeiro_service.dart';
import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

enum _TipoRelatorio { financeiro, atendimentos }

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  _TipoRelatorio _tipo = _TipoRelatorio.financeiro;
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fim = DateTime.now();
  bool _generating = false;

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
    }
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final session = context.read<SessionManager>();
    if (_tipo == _TipoRelatorio.financeiro) {
      final svc = context.read<FinanceiroService>();
      final resumo = await svc.resumo(barbeariaId: session.barbeariaId, inicio: _inicio, fim: _fim);
      final diario = await svc.faturamentoPorDia(barbeariaId: session.barbeariaId, inicio: _inicio, fim: _fim);
      return {'resumo': resumo, 'diario': diario};
    } else {
      final svc = context.read<AtendimentoService>();
      final atendimentos = await svc.listar(barbeariaId: session.barbeariaId, inicio: _inicio, fim: _fim, limit: 200);
      return {'atendimentos': atendimentos};
    }
  }

  Future<void> _gerarPdf() async {
    setState(() => _generating = true);
    try {
      final data = await _fetchData();
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          if (_tipo == _TipoRelatorio.financeiro) {
            final resumo = data['resumo'] as Map<String, dynamic>;
            final diario = data['diario'] as List<Map<String, dynamic>>;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Relatório Financeiro', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('Período: ${Fmt.date(_inicio)} – ${Fmt.date(_fim)}', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 16),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  _pdfKpi('Faturamento', Fmt.currency((resumo['faturamento'] as num?)?.toDouble() ?? 0)),
                  _pdfKpi('Despesas', Fmt.currency((resumo['despesas'] as num?)?.toDouble() ?? 0)),
                  _pdfKpi('Lucro', Fmt.currency((resumo['lucro'] as num?)?.toDouble() ?? 0)),
                ]),
                pw.SizedBox(height: 16),
                pw.Text('Faturamento por dia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]),
                    ...diario.map((row) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(row['dia'] as String? ?? '')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(Fmt.currency((row['valor'] as num?)?.toDouble() ?? 0))),
                    ])),
                  ],
                ),
              ],
            );
          } else {
            return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Relatório de Atendimentos', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Período: ${Fmt.date(_inicio)} – ${Fmt.date(_fim)}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Text('${(data['atendimentos'] as List).length} atendimentos no período.'),
            ]);
          }
        },
      ));
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Erro ao gerar PDF: $e');
    }
    if (mounted) setState(() => _generating = false);
  }

  Future<void> _gerarCsv() async {
    setState(() => _generating = true);
    try {
      final data = await _fetchData();
      List<List<dynamic>> rows;
      String fileName;

      if (_tipo == _TipoRelatorio.financeiro) {
        final diario = data['diario'] as List<Map<String, dynamic>>;
        rows = [
          ['Data', 'Faturamento'],
          ...diario.map((r) => [r['dia'], (r['valor'] as num?)?.toStringAsFixed(2) ?? '0.00']),
        ];
        fileName = 'financeiro_${Fmt.date(_inicio)}_${Fmt.date(_fim)}.csv';
      } else {
        final atendimentos = data['atendimentos'] as List;
        rows = [
          ['Data/Hora', 'Total', 'Pagamento'],
          ...atendimentos.map((a) {
            final at = a as dynamic;
            return [Fmt.dateTime(at.dataHora), at.total.toStringAsFixed(2), at.formaPagamento];
          }),
        ];
        fileName = 'atendimentos_${Fmt.date(_inicio)}_${Fmt.date(_fim)}.csv';
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(csvData.codeUnits);
      final xFile = XFile.fromData(bytes, mimeType: 'text/csv', name: fileName);
      await Share.shareXFiles([xFile], subject: 'Relatório BarberOS');
    } catch (e) {
      if (mounted) UiHelpers.showError(context, 'Erro ao gerar CSV: $e');
    }
    if (mounted) setState(() => _generating = false);
  }

  pw.Widget _pdfKpi(String label, String value) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tipo de relatório', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Financeiro'),
                  selected: _tipo == _TipoRelatorio.financeiro,
                  onSelected: (_) => setState(() => _tipo = _TipoRelatorio.financeiro),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Atendimentos'),
                  selected: _tipo == _TipoRelatorio.atendimentos,
                  onSelected: (_) => setState(() => _tipo = _TipoRelatorio.atendimentos),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Período', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DsCard(
              onTap: _pickRange,
              child: Row(children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${Fmt.date(_inicio)} – ${Fmt.date(_fim)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_fim.difference(_inicio).inDays + 1} dias', style: Theme.of(context).textTheme.bodySmall),
                ]),
                const Spacer(),
                const Icon(Icons.edit_outlined, size: 16),
              ]),
            ),
            const SizedBox(height: 32),
            Text('Exportar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generating ? null : _gerarPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: _generating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Gerar PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _generating ? null : _gerarCsv,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Exportar CSV'),
            ),
          ],
        ),
      ),
    );
  }
}
