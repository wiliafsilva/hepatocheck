import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/usecases/build_exam_evolution.dart';
import '../../domain/usecases/calculate_fib4.dart';
import '../../domain/usecases/summarize_exam_history.dart';
import '../formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import 'fib4_evolution_summary.dart';

enum ExamMetric { fib4, enzymes, platelets }

class ExamEvolutionDashboard extends StatefulWidget {
  const ExamEvolutionDashboard({
    super.key,
    required this.points,
    required this.summary,
  });

  final List<ExamPoint> points;
  final ExamHistorySummary? summary;

  @override
  State<ExamEvolutionDashboard> createState() => _ExamEvolutionDashboardState();
}

class _ExamEvolutionDashboardState extends State<ExamEvolutionDashboard> {
  ExamMetric _metric = ExamMetric.fib4;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registre exames na aba Exames para acompanhar a evolução.',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final summary = widget.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ExamMetric>(
                  segments: const [
                    ButtonSegment(value: ExamMetric.fib4, label: Text('FIB-4')),
                    ButtonSegment(
                      value: ExamMetric.enzymes,
                      label: Text('AST/ALT'),
                    ),
                    ButtonSegment(
                      value: ExamMetric.platelets,
                      label: Text('Plaquetas'),
                    ),
                  ],
                  selected: {_metric},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      setState(() => _metric = selection.first),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: _semanticSummary(points, _metric),
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 200,
                      child: _MetricChart(points: points, metric: _metric),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Legend(
                  metric: _metric,
                  lowCutoff: CalculateFib4.lowCutoffFor(points.last.exam.age),
                ),
                if (_singleDate(points)) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Registre outro exame para ver a evolução.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (summary != null && summary.examCount >= 2) ...[
          const SizedBox(height: 10),
          Fib4EvolutionSummary(summary: summary),
        ],
      ],
    );
  }

  static bool _singleDate(List<ExamPoint> points) => points.every(
    (point) => DateUtils.isSameDay(point.date, points.first.date),
  );

  static String _semanticSummary(List<ExamPoint> points, ExamMetric metric) {
    final values = [
      for (final point in points)
        switch (metric) {
          ExamMetric.fib4 =>
            '${formatDate(point.date)}: FIB-4 ${formatScore(point.fib4.score)}, '
                'faixa ${point.fib4.riskLevel.label}',
          ExamMetric.enzymes =>
            '${formatDate(point.date)}: AST ${formatNumber(point.exam.ast)}, '
                'ALT ${formatNumber(point.exam.alt)}',
          ExamMetric.platelets =>
            '${formatDate(point.date)}: plaquetas '
                '${formatNumber(point.exam.platelets)}',
        },
    ];
    return 'Gráfico da evolução dos exames. ${values.join('. ')}.';
  }
}

class _MetricChart extends StatelessWidget {
  const _MetricChart({required this.points, required this.metric});

  final List<ExamPoint> points;
  final ExamMetric metric;

  static const _astColor = AppColors.olive;
  static const _altColor = Color(0xFF6FA8DC);

  @override
  Widget build(BuildContext context) {
    final first = points.first.date;
    double xOf(ExamPoint point) =>
        DateTime.utc(point.date.year, point.date.month, point.date.day)
            .difference(DateTime.utc(first.year, first.month, first.day))
            .inDays
            .toDouble();

    final xs = [for (final point in points) xOf(point)];
    final minX = xs.first;
    final maxX = xs.last;
    final single = maxX == minX;

    final series = switch (metric) {
      ExamMetric.fib4 => [
        _Series([for (final p in points) p.fib4.score], AppColors.textPrimary),
      ],
      ExamMetric.enzymes => [
        _Series([for (final p in points) p.exam.ast], _astColor),
        _Series([for (final p in points) p.exam.alt], _altColor),
      ],
      ExamMetric.platelets => [
        _Series([for (final p in points) p.exam.platelets], AppColors.olive),
      ],
    };

    final highest = series
        .expand((serie) => serie.values)
        .reduce((a, b) => a > b ? a : b);
    final low = CalculateFib4.lowCutoffFor(points.last.exam.age);
    final maxY = metric == ExamMetric.fib4
        ? (highest * 1.15).clamp(3.5, double.infinity).toDouble()
        : highest * 1.2;

    return LineChart(
      LineChartData(
        minX: single ? minX - 1 : minX,
        maxX: single ? maxX + 1 : maxX,
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.vertical(),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: metric == ExamMetric.fib4
              ? [
                  HorizontalRangeAnnotation(
                    y1: 0,
                    y2: low,
                    color: AppColors.riskGreen.withValues(alpha: 0.10),
                  ),
                  HorizontalRangeAnnotation(
                    y1: low,
                    y2: CalculateFib4.highCutoff,
                    color: AppColors.riskYellow.withValues(alpha: 0.10),
                  ),
                  HorizontalRangeAnnotation(
                    y1: CalculateFib4.highCutoff,
                    y2: maxY,
                    color: AppColors.riskRed.withValues(alpha: 0.10),
                  ),
                ]
              : const [],
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.outline, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    metric == ExamMetric.fib4
                        ? formatScore(value).replaceAll(',00', '')
                        : formatNumber(value.round()),
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: single ? 1 : maxX - minX,
              getTitlesWidget: (value, meta) {
                final index = xs.indexOf(value);
                if (index < 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    formatDayMonthYear(points[index].date),
                    style: AppTextStyles.caption,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceVariant,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${formatDate(points[spot.spotIndex].date)}\n'
                  '${_valueLabel(spot.barIndex, spot.y)}',
                  AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                ),
            ],
          ),
        ),
        lineBarsData: [
          for (final serie in series)
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(xs[i], serie.values[i]),
              ],
              color: serie.color,
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                  radius: 5,
                  color: metric == ExamMetric.fib4
                      ? points[index].fib4.riskLevel.color
                      : serie.color,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _valueLabel(int barIndex, double value) => switch (metric) {
    ExamMetric.fib4 => 'FIB-4 ${formatScore(value)}',
    ExamMetric.enzymes =>
      '${barIndex == 0 ? 'AST' : 'ALT'} ${formatNumber(value)} U/L',
    ExamMetric.platelets => '${formatNumber(value)} ×10³/mm³',
  };
}

class _Series {
  const _Series(this.values, this.color);

  final List<double> values;
  final Color color;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.metric, required this.lowCutoff});

  final ExamMetric metric;
  final double lowCutoff;

  @override
  Widget build(BuildContext context) {
    final low = formatScore(lowCutoff);
    final high = formatScore(CalculateFib4.highCutoff);
    final items = switch (metric) {
      ExamMetric.fib4 => [
        (AppColors.riskGreen, 'Verde < $low'),
        (AppColors.riskYellow, 'Amarelo $low a $high'),
        (AppColors.riskRed, 'Vermelho > $high'),
      ],
      ExamMetric.enzymes => [
        (_MetricChart._astColor, 'AST / TGO (U/L)'),
        (_MetricChart._altColor, 'ALT / TGP (U/L)'),
      ],
      ExamMetric.platelets => [(AppColors.olive, 'Plaquetas (×10³/mm³)')],
    };
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final (color, text) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(text, style: AppTextStyles.caption),
            ],
          ),
      ],
    );
  }
}
