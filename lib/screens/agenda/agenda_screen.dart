import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/agenda_controller.dart';
import '../../models/agendamento.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/ds_widgets.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgendaController>().carregarDia(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      drawer: const AppDrawer(),
      body: Consumer<AgendaController>(
        builder: (context, ctrl, _) => Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: ctrl.diaSelecionado,
              selectedDayPredicate: (d) => isSameDay(d, ctrl.diaSelecionado),
              onDaySelected: (sel, _) => ctrl.carregarDia(sel),
              calendarFormat: CalendarFormat.week,
              locale: 'pt_BR',
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
            const Divider(height: 1),
            Expanded(
              child: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ctrl.agendamentos.isEmpty
                      ? DsEmptyState(message: 'Nenhum agendamento para este dia.', icon: Icons.event_available)
                      : ListView.builder(
                          itemCount: ctrl.agendamentos.length,
                          itemBuilder: (_, i) => _AgendamentoTile(ctrl.agendamentos[i], ctrl),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendamentoTile extends StatelessWidget {
  final Agendamento ag;
  final AgendaController ctrl;

  const _AgendamentoTile(this.ag, this.ctrl);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (ag.status) {
      case 'confirmado': statusColor = AppColors.success; break;
      case 'cancelado': statusColor = AppColors.error; break;
      case 'concluido': statusColor = Colors.grey; break;
      default: statusColor = AppColors.warning;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(Fmt.time(ag.dataHoraInicio), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(Fmt.time(ag.dataHoraFim), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        title: Text('Cliente #${ag.clienteId}'),
        subtitle: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(ag.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        trailing: ag.isPendente || ag.isConfirmado
            ? PopupMenuButton<String>(
                onSelected: (v) => ctrl.atualizarStatus(ag.id!, v),
                itemBuilder: (_) => [
                  if (ag.isPendente) const PopupMenuItem(value: 'confirmado', child: Text('Confirmar')),
                  const PopupMenuItem(value: 'cancelado', child: Text('Cancelar')),
                  const PopupMenuItem(value: 'concluido', child: Text('Concluído')),
                ],
              )
            : null,
      ),
    );
  }
}
