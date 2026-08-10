import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/session_manager.dart';
import '../../utils/app_colors.dart';

class BookingLinkScreen extends StatelessWidget {
  const BookingLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    final barbeariaId = session.barbeariaId;
    // Deep link format — the app intercepts this route
    final bookingUrl = 'https://barberos.app/booking/$barbeariaId';

    return Scaffold(
      appBar: AppBar(title: const Text('Link de Agendamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkDivider),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.link,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Agendamento Online',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compartilhe este link com seus clientes para '
                    'que eles possam agendar horarios online.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // URL Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkDivider),
              ),
              child: Row(
                children: [
                  Icon(Icons.public, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bookingUrl,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppColors.primary),
                    tooltip: 'Copiar link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: bookingUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copiado!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code placeholder
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Simple QR-like visual using the barbeariaId
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2, size: 120, color: Colors.grey.shade800),
                          const SizedBox(height: 8),
                          Text(
                            'QR Code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Imprima ou exiba este QR Code na barbearia',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: bookingUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copiado para a area de transferencia!'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar Link'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                ),
                onPressed: () {
                  final message = 'Agende seu horario online! $bookingUrl';
                  SharePlus.instance.share(ShareParams(text: message));
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  'Compartilhar via WhatsApp',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(ShareParams(text: bookingUrl));
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartilhar'),
              ),
            ),
            const SizedBox(height: 32),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Dicas',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _tipItem('Adicione o link na bio do Instagram'),
                  _tipItem('Envie no grupo de WhatsApp dos clientes'),
                  _tipItem('Imprima o QR Code e coloque no balcao'),
                  _tipItem('Coloque no Google Meu Negocio'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '  •  ',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
