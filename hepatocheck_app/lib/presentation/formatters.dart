import 'package:intl/intl.dart';

import '../domain/entities/consumption_report.dart';
import '../domain/entities/report_period.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

String formatDate(DateTime date) => _dateFormat.format(date);

String formatScore(double score) =>
    score.toStringAsFixed(2).replaceAll('.', ',');

String formatNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString().replaceAll('.', ',');
}

String formatElapsedDays(int days) {
  if (days <= 0) return 'hoje';
  if (days == 1) return 'há 1 dia';
  if (days < 60) return 'há $days dias';
  if (days < 365) return 'há ${days ~/ 30} meses';
  final years = days ~/ 365;
  return years == 1 ? 'há 1 ano' : 'há $years anos';
}

const _monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String formatDayMonth(DateTime date) =>
    '${_twoDigits(date.day)}/${_twoDigits(date.month)}';

String formatDayMonthYear(DateTime date) =>
    '${formatDayMonth(date)}/${_twoDigits(date.year % 100)}';

String formatPeriod(ReportPeriod period) {
  return switch (period.type) {
    ReportPeriodType.week =>
      period.start.year == period.lastDay.year
          ? '${formatDayMonth(period.start)} a ${formatDayMonth(period.lastDay)}'
          : '${formatDate(period.start)} a ${formatDate(period.lastDay)}',
    ReportPeriodType.month =>
      '${_monthNames[period.start.month - 1]} de ${period.start.year}',
  };
}

String formatDrinks(double value) => value.abs().toStringAsFixed(1) == '0.0'
    ? '0,0'
    : value.toStringAsFixed(1).replaceAll('.', ',');

String formatComparisonNote(ConsumptionReport report) {
  final isWeek = report.period.type == ReportPeriodType.week;
  final previous = isWeek ? 'da semana anterior' : 'do mês anterior';
  final days = report.comparedDays == 1
      ? 'o primeiro dia'
      : 'os ${report.comparedDays} primeiros dias';
  if (report.comparesFewerDays) {
    return 'Comparados $days deste mês e do mês anterior, que é mais curto.';
  }
  if (report.inProgress) {
    return 'Período em andamento: comparado com $days $previous, '
        'até o mesmo horário.';
  }
  return 'Comparado com $days $previous, que é mais longo.';
}

double roundedDifference(ConsumptionReport report) =>
    double.parse(report.difference.toStringAsFixed(1));

String formatDifference(double difference) {
  if (difference == 0) return 'Igual';
  final sign = difference > 0 ? '+' : '−';
  return '$sign${formatDrinks(difference.abs())}';
}

String formatChangePercent(ConsumptionReport report) {
  final percent = report.changePercent;
  if (percent == null) return 'sem consumo antes';
  return '${percent.abs().round()}%';
}

const _shortMonthNames = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

String formatMonthYear(DateTime date) =>
    '${_shortMonthNames[date.month - 1]}/${_twoDigits(date.year % 100)}';

String formatMonthName(DateTime date) => _monthNames[date.month - 1];
