import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _storageKey = 'onboarding_completed';

  final _pages = const <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.content_cut,
      title: 'Bem-vindo ao BarberOS',
      description:
          'A solução completa para gerenciar sua barbearia.\n'
          'Controle agendamentos, finanças, estoque e muito mais.',
    ),
    _OnboardingPage(
      icon: Icons.calendar_month,
      title: 'Agenda Inteligente',
      description:
          'Agende horários de forma prática.\n'
          'Visualize a agenda de todos os barbeiros e evite conflitos.',
    ),
    _OnboardingPage(
      icon: Icons.receipt_long,
      title: 'Comandas Digitais',
      description:
          'Registre serviços e produtos em comandas.\n'
          'Controle pagamentos e comissões automaticamente.',
    ),
    _OnboardingPage(
      icon: Icons.bar_chart,
      title: 'Financeiro Completo',
      description:
          'Relatórios detalhados de faturamento.\n'
          'Acompanhe receitas, despesas e lucro em tempo real.',
    ),
    _OnboardingPage(
      icon: Icons.rocket_launch,
      title: 'Vamos Começar!',
      description:
          'Sua barbearia está pronta para decolar.\n'
          'Faça login e comece a usar o BarberOS agora.',
    ),
  ];

  Future<void> _complete() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _storageKey, value: DateTime.now().toIso8601String());
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  static Future<bool> isCompleted() async {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: _storageKey);
    return value != null && value.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _complete,
                  child: Text(
                    'Pular',
                    style: TextStyle(color: AppColors.primary, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : AppColors.darkDivider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next / Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLast
                      ? _complete
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Começar' : 'Próximo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
