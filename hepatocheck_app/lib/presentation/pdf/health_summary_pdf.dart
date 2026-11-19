import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/consumption_report.dart';
import '../../domain/entities/reduction_goal.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/risk_level.dart';
import '../../domain/usecases/build_exam_evolution.dart';
import '../../domain/usecases/build_health_summary.dart';
import '../../domain/usecases/calculate_fib4.dart';
import '../../domain/usecases/evaluate_goal.dart';
import '../../domain/usecases/summarize_exam_history.dart';
import '../formatters.dart';
import '../theme/drink_type_labels.dart';
import '../theme/risk_colors.dart';

class HealthSummaryFonts {
  const HealthSummaryFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static Future<HealthSummaryFonts> fromAssets([AssetBundle? bundle]) async {
    final source = bundle ?? rootBundle;
    final regular = await source.load('assets/fonts/Inter-Regular.ttf');
    final bold = await source.load('assets/fonts/Inter-Bold.ttf');
    return HealthSummaryFonts(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }
}

class HealthSummaryPdf {
  const HealthSummaryPdf(this.fonts);

  static const disclaimer =
      'Triagem preventiva. Não substitui avaliação médica.';

  final HealthSummaryFonts fonts;

  static const _olive = PdfColor.fromInt(0xFF55612F);
  static const _muted = PdfColor.fromInt(0xFF5F6356);
  static const _line = PdfColor.fromInt(0xFFD5D8CC);
  static const _soft = PdfColor.fromInt(0xFFF2F3EE);
  static const _green = PdfColor.fromInt(0xFF2E7D32);
  static const _yellow = PdfColor.fromInt(0xFFB58900);
  static const _red = PdfColor.fromInt(0xFFC62828);

  static String fileName(DateTime date) =>
      'resumo-saude-${date.year}-${_two(date.month)}-${_two(date.day)}.pdf';

  static String _two(int value) => value.toString().padLeft(2, '0');

  Future<Uint8List> build(HealthSummary summary) {
    final document = pw.Document(
      title: 'Resumo de saúde',
      creator: 'HepatoCheck',
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        header: (context) =>
            context.pageNumber == 1 ? _header(summary) : pw.SizedBox.shrink(),
        footer: _footer,
        build: (context) => [
          _riskSection(summary),
          _examSection(summary),
          _consumptionSection(summary.report),
          _byTypeSection(summary.report),
          _goalsSection(summary.goals),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(HealthSummary summary) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _olive, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HepatoCheck',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _olive,
                  ),
                ),
                pw.Text(
                  'Resumo para o profissional de saúde',
                  style: const pw.TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Gerado em ${formatDate(summary.generatedAt)}',
                style: const pw.TextStyle(fontSize: 10, color: _muted),
              ),
              pw.Text(
                'Período: ${_periodLabel(summary.period)}',
                style: const pw.TextStyle(fontSize: 10, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              disclaimer,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _olive,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _riskSection(HealthSummary summary) {
    final risk = summary.risk;
    if (risk == null) {
      return _section('Classificação de risco', [
        pw.Text('Nenhum exame registrado. O FIB-4 não pôde ser calculado.'),
      ]);
    }
    final color = _riskColor(risk.level);
    final exam = risk.exam;
    return _section('Classificação de risco', [
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FIB-4: ${formatScore(risk.fib4.score)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Exame de ${formatDate(exam.examDate)}',
                        style: const pw.TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    risk.level.label.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Faixa do FIB-4: ${risk.fib4.riskLevel.label} '
              '(${_riskRange(risk.fib4.riskLevel, exam.age)}).',
            ),
            if (risk.raisedByConsumption)
              pw.Text(
                'Classificação elevada um nível: o consumo da semana atual, '
                '${formatPeriod(ReportPeriod.containing(summary.generatedAt, ReportPeriodType.week))} '
                '(${formatDrinks(risk.weeklyStandardDrinks)} drinques padrão), '
                'passou da meta de ${risk.weeklyLimit} drinques definida pelo '
                'usuário.',
              ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 24,
              runSpacing: 4,
              children: [
                _keyValue('Idade', '${exam.age} anos'),
                _keyValue('AST / TGO', '${formatNumber(exam.ast)} U/L'),
                _keyValue('ALT / TGP', '${formatNumber(exam.alt)} U/L'),
                _keyValue(
                  'Plaquetas',
                  '${formatNumber(exam.platelets)} ×10³/mm³',
                ),
              ],
            ),
            if (risk.fib4.ageOutsideValidatedRange)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  'Idade fora da faixa validada do FIB-4 (35 a 65 anos).',
                  style: const pw.TextStyle(color: _yellow),
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  pw.Widget _examSection(HealthSummary summary) {
    final points = summary.evolution;
    if (points.isEmpty) return pw.SizedBox.shrink();
    final history = summary.examHistory;
    return _section('Evolução dos exames', [
      if (points.length >= 2) ...[
        pw.SizedBox(height: 140, child: _fib4Chart(points)),
        pw.SizedBox(height: 8),
      ],
      if (history != null && history.examCount >= 2)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(_trendText(history)),
        ),
      _table(
        ['Data', 'FIB-4', 'Faixa', 'AST', 'ALT', 'Plaquetas'],
        [
          for (final point in points.reversed)
            [
              formatDate(point.date),
              formatScore(point.fib4.score),
              point.fib4.riskLevel.label,
              formatNumber(point.exam.ast),
              formatNumber(point.exam.alt),
              formatNumber(point.exam.platelets),
            ],
        ],
        right: {1, 3, 4, 5},
      ),
    ]);
  }

  pw.Widget _fib4Chart(List<ExamPoint> points) {
    final highest = points
        .map((point) => point.fib4.score)
        .reduce((a, b) => a > b ? a : b);
    final top = (highest > 3.5 ? highest * 1.15 : 3.5);
    final low = CalculateFib4.lowCutoffFor(points.last.exam.age);
    final first = _dayOf(points.first.date);
    final offsets = [
      for (final point in points)
        _dayOf(point.date).difference(first).inDays.toDouble(),
    ];
    final span = offsets.last;
    final labels = {
      for (final index in _labelIndexes(points.length))
        offsets[index]: formatDayMonthYear(points[index].date),
    };
    final ticks = <double>[];
    for (final tick in labels.keys) {
      if (ticks.isNotEmpty && tick - ticks.last < span / 8) {
        if (tick != span) continue;
        ticks.removeLast();
      }
      ticks.add(tick);
    }
    if (span == 0) {
      ticks
        ..insert(0, -1)
        ..add(1);
    }
    return pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis(
          ticks,
          format: (value) => labels[value.toDouble()] ?? '',
          marginStart: 20,
          marginEnd: 20,
          textStyle: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        yAxis: pw.FixedAxis(
          [0, low, CalculateFib4.highCutoff, top],
          format: (value) => formatScore(value.toDouble()),
          divisions: true,
          divisionsColor: _line,
          textStyle: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ),
      datasets: [
        pw.LineDataSet(
          data: [
            for (final (index, point) in points.indexed)
              pw.PointChartValue(offsets[index], point.fib4.score),
          ],
          color: _olive,
          pointColor: _olive,
          pointSize: 3,
          lineWidth: 1.5,
        ),
      ],
    );
  }

  static const _maxDateLabels = 6;

  static List<int> _labelIndexes(int count) {
    if (count <= _maxDateLabels) return [for (var i = 0; i < count; i++) i];
    return [
      for (var k = 0; k < _maxDateLabels; k++)
        (k * (count - 1) / (_maxDateLabels - 1)).round(),
    ];
  }

  static DateTime _dayOf(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  pw.Widget _consumptionSection(ConsumptionReport report) {
    final previous = report.period.type == ReportPeriodType.week
        ? 'semana anterior'
        : 'mês anterior';
    final difference = roundedDifference(report);
    return _section('Consumo de álcool no período', [
      pw.Wrap(
        spacing: 24,
        runSpacing: 6,
        children: [
          _keyValue(
            'Drinques padrão',
            formatDrinks(report.totalStandardDrinks),
          ),
          _keyValue('Média por dia', formatDrinks(report.averagePerDay)),
          _keyValue(
            'Dias sem álcool',
            '${report.alcoholFreeDays} de ${report.elapsedDays}',
          ),
          _keyValue(
            'Vs. $previous',
            difference == 0
                ? formatDifference(difference)
                : '${formatDifference(difference)} '
                      '(${formatChangePercent(report)})',
          ),
        ],
      ),
      if (report.hasComparisonNote)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            formatComparisonNote(report),
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
      pw.SizedBox(height: 10),
      if (report.hasData)
        _dailyBars(report)
      else
        pw.Text('Nenhum drinque registrado neste período.'),
      pw.SizedBox(height: 4),
      pw.Text(
        'Um drinque padrão equivale a 14 g de álcool puro.',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
    ]);
  }

  pw.Widget _dailyBars(ConsumptionReport report) {
    final daily = report.daily;
    final highest = daily
        .map((day) => day.standardDrinks)
        .reduce((a, b) => a > b ? a : b);
    final isWeek = report.period.type == ReportPeriodType.week;
    const barArea = 70.0;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (final day in daily)
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (isWeek && day.standardDrinks > 0)
                  pw.Text(
                    formatDrinks(day.standardDrinks),
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                pw.Container(
                  height: highest <= 0
                      ? 0
                      : barArea * day.standardDrinks / highest,
                  margin: pw.EdgeInsets.symmetric(horizontal: isWeek ? 10 : 1),
                  color: _olive,
                ),
                pw.Container(height: 0.5, color: _line),
                pw.SizedBox(height: 2),
                pw.Text(
                  isWeek
                      ? formatDayMonth(day.day)
                      : (day.day.day == 1 || day.day.day % 5 == 0
                            ? '${day.day.day}'
                            : ''),
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _byTypeSection(ConsumptionReport report) {
    final entries =
        report.byType.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return pw.SizedBox.shrink();
    return pw.Inseparable(
      child: _section('Consumo por tipo de bebida', [
        _table(
          ['Bebida', 'Drinques padrão'],
          [
            for (final entry in entries)
              [entry.key.label, formatDrinks(entry.value)],
          ],
          right: {1},
        ),
      ]),
    );
  }

  pw.Widget _goalsSection(List<GoalProgress> goals) {
    if (goals.isEmpty) {
      return pw.Inseparable(
        child: _section('Metas de redução', [
          pw.Text('Nenhuma meta ativa no período.'),
        ]),
      );
    }
    if (goals.length > 12) {
      return _goalsTable(goals);
    }
    return pw.Inseparable(child: _goalsTable(goals));
  }

  pw.Widget _goalsTable(List<GoalProgress> goals) {
    return _section('Metas de redução', [
      _table(
        ['Semana', 'Meta', 'Resultado', 'Situação'],
        [
          for (final progress in goals)
            [
              '${formatDayMonth(progress.week.start)} a '
                  '${formatDayMonth(progress.week.lastDay)}',
              _goalLabel(progress.goal),
              progress.goal.type == GoalType.maxDrinksPerWeek
                  ? '${formatDrinks(progress.value)} drinques'
                  : '${progress.value.round()} dias',
              _statusLabel(progress.status),
            ],
        ],
      ),
    ]);
  }

  pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    Set<int> right = const {},
  }) {
    final alignments = {
      for (var i = 0; i < headers.length; i++)
        i: right.contains(i)
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
    };
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: _soft),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
      ),
      headerAlignments: alignments,
      cellAlignments: alignments,
    );
  }

  pw.Widget _keyValue(String key, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(key, style: const pw.TextStyle(fontSize: 9, color: _muted)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static String _periodLabel(ReportPeriod period) =>
      period.type == ReportPeriodType.week
      ? 'semana de ${formatDate(period.start)} a ${formatDate(period.lastDay)}'
      : formatPeriod(period);

  static String _trendText(ExamHistorySummary history) {
    final trend = switch (history.trend) {
      Fib4Trend.improved => 'melhorou',
      Fib4Trend.worsened => 'piorou',
      Fib4Trend.stable => 'ficou estável',
    };
    return 'O FIB-4 $trend: de ${formatScore(history.first.score)} '
        '(${formatDate(history.firstDate)}) para '
        '${formatScore(history.latest.score)} '
        '(${formatDate(history.latestDate)}), em ${history.examCount} exames.';
  }

  static PdfColor _riskColor(RiskLevel level) => switch (level) {
    RiskLevel.low => _green,
    RiskLevel.intermediate => _yellow,
    RiskLevel.high => _red,
  };

  static String _riskRange(RiskLevel level, int age) {
    final low = formatScore(CalculateFib4.lowCutoffFor(age));
    final high = formatScore(CalculateFib4.highCutoff);
    return switch (level) {
      RiskLevel.low => 'abaixo de $low',
      RiskLevel.intermediate => '$low a $high',
      RiskLevel.high => 'acima de $high',
    };
  }

  static String _goalLabel(ReductionGoal goal) =>
      goal.type == GoalType.maxDrinksPerWeek
      ? 'Até ${goal.target} drinques'
      : '${goal.target} dias sem álcool';

  static String _statusLabel(GoalStatus status) => switch (status) {
    GoalStatus.upcoming => 'A começar',
    GoalStatus.progressing => 'Em andamento',
    GoalStatus.nearLimit => 'Perto do limite',
    GoalStatus.exceeded => 'Não cumprida',
    GoalStatus.achieved => 'Cumprida',
  };
}
