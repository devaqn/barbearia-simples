import 'package:intl/intl.dart';

abstract class Fmt {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final _time = DateFormat('HH:mm', 'pt_BR');
  static final _shortDate = DateFormat('dd/MM', 'pt_BR');
  static final _monthYear = DateFormat('MMM/yyyy', 'pt_BR');

  static String currency(double value) => _currency.format(value);
  static String date(DateTime? dt) => dt == null ? '--' : _date.format(dt);
  static String dateTime(DateTime? dt) => dt == null ? '--' : _dateTime.format(dt);
  static String time(DateTime? dt) => dt == null ? '--' : _time.format(dt);
  static String shortDate(DateTime? dt) => dt == null ? '--' : _shortDate.format(dt);
  static String monthYear(DateTime? dt) => dt == null ? '--' : _monthYear.format(dt);

  static String duration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  static String percent(double value) =>
      '${value.toStringAsFixed(1).replaceAll('.', ',')}%';

  static String points(int pts) => '$pts pts';

  static DateTime? parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return _date.parse(s);
    } catch (_) {
      return DateTime.tryParse(s);
    }
  }
}
