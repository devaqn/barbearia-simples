import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/agendamento.dart';
import '../models/cliente.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../utils/formatters.dart';

class WhatsAppService {
  static Future<bool> abrirWhatsApp(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('55')) return digits;
    if (digits.length == 11 || digits.length == 10) return '55$digits';
    return digits;
  }

  static Uri lembreteAgendamentoUri({
    required Cliente cliente,
    required Agendamento agendamento,
    required Servico? servico,
    required Usuario? barbeiro,
    required String nomeBarbearia,
  }) {
    final data = Fmt.date(agendamento.dataHoraInicio);
    final hora = Fmt.time(agendamento.dataHoraInicio);
    final servicoNome = servico?.nome ?? 'Atendimento';
    final barbeiroNome = barbeiro?.nome ?? '';

    final msg = StringBuffer()
      ..writeln('Olá ${cliente.nome}! 👋')
      ..writeln()
      ..writeln('Lembrete do seu agendamento na *$nomeBarbearia*:')
      ..writeln()
      ..writeln('📅 $data às $hora')
      ..writeln('✂️ $servicoNome');
    if (barbeiroNome.isNotEmpty) {
      msg.writeln('💈 Barbeiro: $barbeiroNome');
    }
    if (servico != null) {
      msg.writeln('💰 ${Fmt.currency(servico.preco)}');
    }
    msg
      ..writeln()
      ..writeln('Te esperamos! 🙂');

    final phone = _formatPhone(cliente.telefone);
    return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg.toString())}');
  }

  static Uri aniversarioUri({
    required Cliente cliente,
    required String nomeBarbearia,
  }) {
    final msg = StringBuffer()
      ..writeln('Parabéns ${cliente.nome}! 🎂🎉')
      ..writeln()
      ..writeln('A equipe da *$nomeBarbearia* deseja um feliz aniversário!')
      ..writeln()
      ..writeln('Venha comemorar com a gente — temos uma surpresa especial pra você! 🎁');

    final phone = _formatPhone(cliente.telefone);
    return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg.toString())}');
  }

  static Uri clienteSumidoUri({
    required Cliente cliente,
    required String nomeBarbearia,
  }) {
    final msg = StringBuffer()
      ..writeln('Olá ${cliente.nome}! 👋')
      ..writeln()
      ..writeln('Sentimos sua falta na *$nomeBarbearia*!')
      ..writeln()
      ..writeln('Faz tempo que não nos vemos. Que tal agendar um horário?')
      ..writeln()
      ..writeln('Temos novidades esperando por você! ✂️');

    final phone = _formatPhone(cliente.telefone);
    return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg.toString())}');
  }

  static Uri confirmacaoBookingUri({
    required String clienteNome,
    required String clienteTelefone,
    required String servicoNome,
    required String barbeiroNome,
    required DateTime dataHora,
    required String nomeBarbearia,
  }) {
    final data = Fmt.date(dataHora);
    final hora = Fmt.time(dataHora);

    final msg = StringBuffer()
      ..writeln('✅ Agendamento confirmado!')
      ..writeln()
      ..writeln('*$nomeBarbearia*')
      ..writeln('📅 $data às $hora')
      ..writeln('✂️ $servicoNome')
      ..writeln('💈 $barbeiroNome')
      ..writeln()
      ..writeln('Até lá, $clienteNome! 😊');

    final phone = _formatPhone(clienteTelefone);
    return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg.toString())}');
  }

  static Uri linkAgendamentoUri({
    required String telefone,
    required String nomeBarbearia,
    required String bookingUrl,
  }) {
    final msg = StringBuffer()
      ..writeln('Olá! 👋')
      ..writeln()
      ..writeln('Agende seu horário na *$nomeBarbearia* pelo link:')
      ..writeln(bookingUrl)
      ..writeln()
      ..writeln('Rápido e fácil! 📱');

    final phone = _formatPhone(telefone);
    return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg.toString())}');
  }

  static Future<void> compartilharLink({
    required String nomeBarbearia,
    required String bookingUrl,
    Rect? sharePositionOrigin,
  }) async {
    final msg = StringBuffer()
      ..writeln('Agende seu horário na *$nomeBarbearia*! ✂️')
      ..writeln()
      ..writeln('$bookingUrl')
      ..writeln()
      ..writeln('Escolha o serviço, barbeiro e horário — tudo online! 📱');

    await SharePlus.instance.share(
      ShareParams(
        text: msg.toString(),
        subject: '$nomeBarbearia - Agendamento Online',
      ),
    );
  }
}
