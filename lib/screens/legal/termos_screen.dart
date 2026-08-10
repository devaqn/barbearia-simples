import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';

class TermosScreen extends StatefulWidget {
  const TermosScreen({super.key});

  @override
  State<TermosScreen> createState() => _TermosScreenState();
}

class _TermosScreenState extends State<TermosScreen> {
  static const _storageKey = 'termos_aceitos_em';
  bool _viewOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['viewOnly'] == true) {
      _viewOnly = true;
    }
  }

  Future<void> _aceitar() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _storageKey, value: DateTime.now().toIso8601String());
    if (mounted) Navigator.pop(context, true);
  }

  void _recusar() {
    Navigator.pop(context, false);
  }

  static Future<bool> foiAceito() async {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: _storageKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('1. Uso do Aplicativo', '''
O BarberOS é uma plataforma de gestão para barbearias. Ao utilizar este aplicativo, você concorda em:

- Fornecer informações verdadeiras e atualizadas;
- Utilizar o aplicativo apenas para fins de gestão da sua barbearia;
- Manter a confidencialidade das suas credenciais de acesso;
- Não compartilhar sua conta com terceiros não autorizados.'''),
                  _section('2. Dados e Informações', '''
Ao utilizar o BarberOS, você é responsável por:

- Os dados inseridos no sistema, incluindo informações de clientes;
- Manter backups das informações importantes;
- Garantir que possui consentimento dos clientes para armazenar seus dados;
- Cumprir a LGPD (Lei Geral de Proteção de Dados) no tratamento dos dados.'''),
                  _section('3. Pagamentos e Licenciamento', '''
- O uso do BarberOS requer uma licença válida;
- A licença é pessoal e intransferível;
- O pagamento da licença garante acesso às funcionalidades do aplicativo;
- A revogação da licença implica na suspensão do acesso ao sistema.'''),
                  _section('4. Responsabilidades', '''
O BarberOS:

- Não se responsabiliza por perdas de dados causadas por mau uso;
- Não garante disponibilidade ininterrupta do serviço;
- Reserva-se o direito de atualizar estes termos;
- Pode suspender contas que violem estes termos.

O uso continuado do aplicativo após alterações nos termos constitui aceitação das modificações.'''),
                  _section('5. Propriedade Intelectual', '''
- Todo o software, design e conteúdo do BarberOS são protegidos por direitos autorais;
- É proibida a reprodução, modificação ou distribuição sem autorização;
- A licença concedida é de uso, não de propriedade.'''),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.privacidade),
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text('Ver Política de Privacidade'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Última atualização: Junho 2026',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (!_viewOnly) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _recusar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _aceitar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body.trim(),
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
          ),
        ],
      ),
    );
  }
}
