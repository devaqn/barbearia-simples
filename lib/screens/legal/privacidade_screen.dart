import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class PrivacidadeScreen extends StatelessWidget {
  const PrivacidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('1. Dados Coletados', '''
O BarberOS coleta e armazena os seguintes dados:

- Informações de cadastro: nome, e-mail, telefone;
- Dados de clientes: nome, telefone, e-mail, data de nascimento;
- Registros de atendimentos, agendamentos e comandas;
- Dados financeiros: faturamento, despesas, comissões;
- Informações de estoque e produtos;
- Dados de uso do aplicativo para melhoria do serviço.'''),
            _section('2. Uso dos Dados', '''
Os dados coletados são utilizados para:

- Fornecer as funcionalidades de gestão da barbearia;
- Gerar relatórios e análises de desempenho;
- Sincronizar informações entre dispositivos;
- Enviar notificações relevantes ao funcionamento da barbearia;
- Melhorar a experiência de uso do aplicativo.'''),
            _section('3. Compartilhamento', '''
O BarberOS não vende ou compartilha seus dados pessoais com terceiros, exceto:

- Serviços de infraestrutura (Firebase/Google Cloud) para armazenamento e sincronização;
- Processadores de pagamento quando aplicável;
- Quando exigido por lei ou ordem judicial.'''),
            _section('4. Direitos do Usuário (LGPD)', '''
Em conformidade com a Lei Geral de Proteção de Dados (Lei 13.709/2018), você tem direito a:

- Acesso: solicitar quais dados seus estão armazenados;
- Correção: pedir a atualização de dados incompletos ou incorretos;
- Exclusão: solicitar a remoção dos seus dados pessoais;
- Portabilidade: receber seus dados em formato legível;
- Revogação: retirar o consentimento para o tratamento dos dados;
- Informação: saber com quem seus dados são compartilhados.

Para exercer qualquer desses direitos, entre em contato conosco.'''),
            _section('5. Segurança', '''
Implementamos medidas técnicas e organizacionais para proteger seus dados:

- Criptografia do banco de dados local (SQLCipher);
- Comunicação segura via HTTPS;
- Autenticação segura via Firebase Auth;
- Armazenamento seguro de credenciais;
- Controle de acesso baseado em funções (admin/barbeiro).'''),
            _section('6. Contato', '''
Para questões sobre privacidade ou exercício dos seus direitos:

E-mail: suporte@barberos.app
Encarregado de Dados (DPO): dpo@barberos.app

Responderemos sua solicitação em até 15 dias úteis, conforme previsto na LGPD.'''),
            const SizedBox(height: 16),
            Text(
              'Última atualização: Junho 2026',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
