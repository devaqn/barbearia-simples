import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/booking_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingService = BookingService();
  final _pageController = PageController();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String _barbeariaId = '';
  String _barbeariaName = '';
  bool _loading = true;
  String? _error;

  // Data
  List<Map<String, dynamic>> _servicos = [];
  List<Map<String, dynamic>> _barbeiros = [];
  List<DateTime> _horariosDisponiveis = [];

  // Selections
  Map<String, dynamic>? _selectedServico;
  Map<String, dynamic>? _selectedBarbeiro;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedTime;

  static const _stepTitles = [
    'Escolha o Servico',
    'Escolha o Profissional',
    'Escolha a Data',
    'Escolha o Horario',
    'Seus Dados',
    'Confirmacao',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! String || args.isEmpty) {
      setState(() {
        _error = 'Link de agendamento invalido.';
        _loading = false;
      });
      return;
    }
    _barbeariaId = args;

    try {
      final results = await Future.wait([
        _bookingService.getBarbeariaName(_barbeariaId),
        _bookingService.getServicos(_barbeariaId),
        _bookingService.getBarbeiros(_barbeariaId),
      ]);
      setState(() {
        _barbeariaName = results[0] as String;
        _servicos = results[1] as List<Map<String, dynamic>>;
        _barbeiros = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nao foi possivel carregar os dados. Tente novamente.';
        _loading = false;
      });
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 5) _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> _loadHorarios() async {
    if (_selectedBarbeiro == null || _selectedServico == null) return;

    setState(() => _loading = true);
    try {
      final barbeiroId = _selectedBarbeiro!['id'] as int;
      final agendamentos = await _bookingService.getAgendamentosDia(
        _barbeariaId,
        barbeiroId,
        _selectedDate,
      );
      final duracao = (_selectedServico!['duracao_minutos'] as int?) ?? 30;
      setState(() {
        _horariosDisponiveis = _bookingService.getHorariosDisponiveis(
          dia: _selectedDate,
          duracaoMinutos: duracao,
          agendamentosExistentes: agendamentos,
        );
        _selectedTime = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _horariosDisponiveis = [];
        _loading = false;
      });
    }
  }

  Future<void> _confirmarAgendamento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServico == null ||
        _selectedBarbeiro == null ||
        _selectedTime == null) return;

    setState(() => _loading = true);

    try {
      final duracao = (_selectedServico!['duracao_minutos'] as int?) ?? 30;
      final fim = _selectedTime!.add(Duration(minutes: duracao));

      // Find or create client
      final cliente = await _bookingService.findOrCreateCliente(
        barbeariaId: _barbeariaId,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
      );

      final clienteId = (cliente['id'] as int?) ?? 0;

      // Create appointment
      await _bookingService.criarAgendamento(
        barbeariaId: _barbeariaId,
        clienteId: clienteId,
        clienteFirebaseId: cliente['firebase_id'] as String,
        barbeiroId: _selectedBarbeiro!['id'] as int,
        servicoId: _selectedServico!['id'] as int?,
        servicoFirebaseId: _selectedServico!['firebase_id'] as String?,
        dataHoraInicio: _selectedTime!,
        dataHoraFim: fim,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingConfirmation,
        arguments: {
          'barbeariaName': _barbeariaName,
          'servico': _selectedServico!['nome'],
          'barbeiro': _selectedBarbeiro!['nome'],
          'data': _selectedTime!,
          'duracao': duracao,
          'preco': _selectedServico!['preco'],
          'clienteNome': _nomeController.text.trim(),
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao agendar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildError();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: _loading && _servicos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildServicosStep(),
                        _buildBarbeirosStep(),
                        _buildDateStep(),
                        _buildTimeStep(),
                        _buildClientInfoStep(),
                        _buildConfirmationStep(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.content_cut, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _barbeariaName.isEmpty ? 'Carregando...' : _barbeariaName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Agendamento Online',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(6, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone || isActive
                              ? AppColors.primary
                              : AppColors.darkDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 5) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _prevStep,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios,
                          size: 14, color: AppColors.primary),
                      Text(
                        'Voltar',
                        style: TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                'Passo ${_currentStep + 1} de 6',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Step 1: Services ----
  Widget _buildServicosStep() {
    if (_servicos.isEmpty) {
      return _buildEmptyState(
        Icons.design_services_outlined,
        'Nenhum servico disponivel no momento.',
      );
    }

    return _buildStepLayout(
      title: 'Qual servico voce deseja?',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _servicos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = _servicos[i];
          final selected = _selectedServico == s;
          final preco = (s['preco'] as num?)?.toDouble() ?? 0;
          final duracao = (s['duracao_minutos'] as int?) ?? 30;

          return _SelectionCard(
            selected: selected,
            onTap: () {
              setState(() => _selectedServico = s);
              _nextStep();
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.darkDivider.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.content_cut,
                    color: selected ? AppColors.primary : Colors.white54,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['nome'] as String? ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      if (s['descricao'] != null && (s['descricao'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            s['descricao'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.white.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            Fmt.duration(duracao),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  Fmt.currency(preco),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Step 2: Barbers ----
  Widget _buildBarbeirosStep() {
    if (_barbeiros.isEmpty) {
      return _buildEmptyState(
        Icons.person_off_outlined,
        'Nenhum profissional disponivel.',
      );
    }

    return _buildStepLayout(
      title: 'Com quem voce quer agendar?',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _barbeiros.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final b = _barbeiros[i];
          final selected = _selectedBarbeiro == b;
          final nome = b['nome'] as String? ?? '';

          return _SelectionCard(
            selected: selected,
            onTap: () {
              setState(() => _selectedBarbeiro = b);
              _nextStep();
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: selected
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.darkDivider.withOpacity(0.3),
                  child: Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? AppColors.primary : Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Profissional',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Step 3: Date ----
  Widget _buildDateStep() {
    return _buildStepLayout(
      title: 'Escolha a data',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selected, focused) {
                  setState(() => _selectedDate = selected);
                  _loadHorarios();
                  _nextStep();
                },
                locale: 'pt_BR',
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.white70),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Step 4: Time ----
  Widget _buildTimeStep() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_horariosDisponiveis.isEmpty) {
      return _buildStepLayout(
        title: 'Horarios disponiveis',
        child: _buildEmptyState(
          Icons.schedule,
          'Nenhum horario disponivel para esta data.\nTente outra data ou profissional.',
        ),
      );
    }

    final timeFormat = DateFormat('HH:mm');

    return _buildStepLayout(
      title: 'Horarios disponiveis em ${Fmt.date(_selectedDate)}',
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
        ),
        itemCount: _horariosDisponiveis.length,
        itemBuilder: (_, i) {
          final slot = _horariosDisponiveis[i];
          final selected = _selectedTime == slot;

          return Material(
            color: selected ? AppColors.primary : AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _selectedTime = slot);
                _nextStep();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.darkDivider,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  timeFormat.format(slot),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Step 5: Client Info ----
  Widget _buildClientInfoStep() {
    return _buildStepLayout(
      title: 'Seus dados',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Precisamos de algumas informacoes para confirmar seu agendamento.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe seu nome';
                  if (v.trim().length < 3) return 'Nome muito curto';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone (WhatsApp)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '(11) 99999-9999',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe seu telefone';
                  if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                    return 'Telefone invalido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _nextStep();
                    }
                  },
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Step 6: Confirmation ----
  Widget _buildConfirmationStep() {
    final preco = (_selectedServico?['preco'] as num?)?.toDouble() ?? 0;
    final duracao = (_selectedServico?['duracao_minutos'] as int?) ?? 30;

    return _buildStepLayout(
      title: 'Confirme seu agendamento',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkDivider),
              ),
              child: Column(
                children: [
                  _summaryRow(Icons.content_cut, 'Servico',
                      _selectedServico?['nome'] as String? ?? ''),
                  const Divider(height: 24),
                  _summaryRow(Icons.person, 'Profissional',
                      _selectedBarbeiro?['nome'] as String? ?? ''),
                  const Divider(height: 24),
                  _summaryRow(Icons.calendar_today, 'Data',
                      Fmt.date(_selectedDate)),
                  const Divider(height: 24),
                  _summaryRow(Icons.access_time, 'Horario',
                      _selectedTime != null ? Fmt.time(_selectedTime!) : '--'),
                  const Divider(height: 24),
                  _summaryRow(Icons.timer_outlined, 'Duracao',
                      Fmt.duration(duracao)),
                  const Divider(height: 24),
                  _summaryRow(Icons.attach_money, 'Valor',
                      Fmt.currency(preco)),
                  const Divider(height: 24),
                  _summaryRow(Icons.person_outline, 'Cliente',
                      _nomeController.text),
                  const Divider(height: 24),
                  _summaryRow(Icons.phone, 'Telefone',
                      _telefoneController.text),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmarAgendamento,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmar Agendamento'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text('Voltar'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLayout({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectionCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.darkDivider,
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
