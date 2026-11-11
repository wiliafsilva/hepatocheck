import 'package:intl/intl.dart';

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

String formatDrinks(double value) {
  final rounded = double.parse(value.toStringAsFixed(1));
  return formatNumber(rounded);
}
