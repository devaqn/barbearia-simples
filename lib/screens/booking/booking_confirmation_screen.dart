import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('Dados nao encontrados.')));
    }

    final barbeariaName = args['barbeariaName'] as String? ?? '';
    final servico = args['servico'] as String? ?? '';
    final barbeiro = args['barbeiro'] as String? ?? '';
    final data = args['data'] as DateTime;
    final duracao = args['duracao'] as int? ?? 30;
    final preco = (args['preco'] as num?)?.toDouble() ?? 0;
    final clienteNome = args['clienteNome'] as String? ?? '';
    final fim = data.add(Duration(minutes: duracao));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Success animation area
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Agendamento Confirmado!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$clienteNome, seu horario esta reservado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Booking details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkDivider),
                ),
                child: Column(
                  children: [
                    Text(
                      barbeariaName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow(Icons.content_cut, servico),
                    const SizedBox(height: 12),
                    _detailRow(Icons.person, barbeiro),
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.calendar_today,
                      Fmt.date(data),
                    ),
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.access_time,
                      '${Fmt.time(data)} - ${Fmt.time(fim)}',
                    ),
                    const SizedBox(height: 12),
                    _detailRow(
                      Icons.attach_money,
                      Fmt.currency(preco),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Share via WhatsApp
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: () => _shareViaWhatsApp(
                    barbeariaName: barbeariaName,
                    servico: servico,
                    barbeiro: barbeiro,
                    data: data,
                    fim: fim,
                    preco: preco,
                  ),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Compartilhar via WhatsApp',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Close / back
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Fechar'),
                ),
              ),
              const SizedBox(height: 24),

              // Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chegue com 5 minutos de antecedencia. '
                        'Em caso de imprevistos, avise com antecedencia.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _shareViaWhatsApp({
    required String barbeariaName,
    required String servico,
    required String barbeiro,
    required DateTime data,
    required DateTime fim,
    required double preco,
  }) {
    final message = '''
Agendamento confirmado! ✅

📍 $barbeariaName
✂️ $servico
💈 $barbeiro
📅 ${Fmt.date(data)}
🕐 ${Fmt.time(data)} - ${Fmt.time(fim)}
💰 ${Fmt.currency(preco)}

Agendado pelo BarberOS
''';

    SharePlus.instance.share(ShareParams(text: message.trim()));
  }
}
