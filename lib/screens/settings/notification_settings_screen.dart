import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/ds_widgets.dart';
import '../../widgets/ui_helpers.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const _storage = FlutterSecureStorage();
  static const _keyAgendamentos = 'notif_agendamentos';
  static const _keyPromocoes = 'notif_promocoes';
  static const _keyCaixa = 'notif_caixa';

  bool _agendamentos = true;
  bool _promocoes = true;
  bool _caixa = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final ag = await _storage.read(key: _keyAgendamentos);
    final pr = await _storage.read(key: _keyPromocoes);
    final cx = await _storage.read(key: _keyCaixa);

    if (!mounted) return;
    setState(() {
      _agendamentos = ag != 'false';
      _promocoes = pr != 'false';
      _caixa = cx != 'false';
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool value, String topicSuffix) async {
    await _storage.write(key: key, value: value.toString());

    final session = context.read<SessionManager>();
    final notifSvc = context.read<NotificationService>();
    final topic = 'barbearia_${session.barbeariaId}_$topicSuffix';

    if (value) {
      await notifSvc.subscribeToTopic(topic);
    } else {
      await notifSvc.unsubscribeFromTopic(topic);
    }

    if (mounted) UiHelpers.showSuccess(context, 'Preferência salva');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferências de notificação',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha quais notificações deseja receber.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _NotifToggle(
                  icon: Icons.calendar_month_outlined,
                  title: 'Agendamentos',
                  subtitle: 'Lembretes de horários marcados',
                  value: _agendamentos,
                  onChanged: (v) {
                    setState(() => _agendamentos = v);
                    _toggle(_keyAgendamentos, v, 'agendamentos');
                  },
                ),
                _NotifToggle(
                  icon: Icons.local_offer_outlined,
                  title: 'Promoções',
                  subtitle: 'Ofertas e novidades da barbearia',
                  value: _promocoes,
                  onChanged: (v) {
                    setState(() => _promocoes = v);
                    _toggle(_keyPromocoes, v, 'promocoes');
                  },
                ),
                _NotifToggle(
                  icon: Icons.point_of_sale_outlined,
                  title: 'Caixa',
                  subtitle: 'Abertura e fechamento de caixa',
                  value: _caixa,
                  onChanged: (v) {
                    setState(() => _caixa = v);
                    _toggle(_keyCaixa, v, 'caixa');
                  },
                ),
              ],
            ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
