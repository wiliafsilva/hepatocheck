import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/usecases/build_risk_evolution.dart';
import '../../domain/usecases/calculate_fib4.dart';
import '../formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';

enum RiskSeries { meter, fib4 }

/// Evolução temporal do risco hepático: gráfico de linha do medidor do fígado
/// (0 a 100%) ou do FIB-4, com um ponto por exame. Indicador educativo, não
/// resultado clínico (RNF17).
class RiskEvolutionChart extends StatefulWidget {
  const RiskEvolutionChart({super.key, required this.points});

  final List<RiskEvolutionPoint> points;

  @override
  State<RiskEvolutionChart> createState() => _RiskEvolutionChartState();
}

class _RiskEvolutionChartState extends State<RiskEvolutionChart> {
  RiskSeries _series = RiskSeries.meter;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('Evolução do risco', style: AppTextStyles.subtitle),
            ),
            const SizedBox(height: 12),
            if (points.isEmpty)
              const Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  'Registre exames na aba Exames para acompanhar como o '
                  'risco muda ao longo do tempo.',
                  style: AppTextStyles.body,
                ),
              )
            else ...[
              SegmentedButton<RiskSeries>(
                segments: const [
                  ButtonSegment(
                    value: RiskSeries.meter,
                    label: Text('Medidor'),
                  ),
                  ButtonSegment(value: RiskSeries.fib4, label: Text('FIB-4')),
                ],
                selected: {_series},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _series = selection.first),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: semanticSummary(points, _series),
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 200,
                    child: _Chart(points: points, series: _series),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                points.length == 1
                    ? 'Registre outro exame para ver a evolução.'
                    : 'Cada ponto é um exame. A cor do ponto é a faixa de '
                          'risco. Indicador educativo, não é resultado '
                          'clínico.',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String semanticSummary(
    List<RiskEvolutionPoint> points,
    RiskSeries series,
  ) {
    final values = [
      for (final point in points)
        '${formatDate(point.date)}: '
            '${series == RiskSeries.meter ? 'medidor ${point.percent.round()}%' : 'FIB-4 ${formatScore(point.fib4)}'}, '
            '${point.risk.label}',
    ];
    return 'Gráfico da evolução do risco. ${values.join('. ')}.';
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points, required this.series});

  final List<RiskEvolutionPoint> points;
  final RiskSeries series;

  bool get _isMeter => series == RiskSeries.meter;

  double _valueOf(RiskEvolutionPoint point) =>
      _isMeter ? point.percent : point.fib4;

  @override
  Widget build(BuildContext context) {
    final first = points.first.date;
    double xOf(RiskEvolutionPoint point) =>
        DateTime.utc(point.date.year, point.date.month, point.date.day)
            .difference(DateTime.utc(first.year, first.month, first.day))
            .inDays
            .toDouble();

    final xs = [for (final point in points) xOf(point)];
    final minX = xs.first;
    final maxX = xs.last;
    final single = maxX == minX;

    final highest = points.map(_valueOf).reduce((a, b) => a > b ? a : b);
    final maxY = _isMeter
        ? 100.0
        : (highest * 1.15).clamp(3.5, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        minX: single ? minX - 1 : minX,
        maxX: single ? maxX + 1 : maxX,
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.vertical(),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: _isMeter
              ? const []
              : [
                  HorizontalRangeAnnotation(
                    y1: 0,
                    y2: CalculateFib4.lowCutoff,
                    color: AppColors.riskGreen.withValues(alpha: 0.10),
                  ),
                  HorizontalRangeAnnotation(
                    y1: CalculateFib4.lowCutoff,
                    y2: CalculateFib4.highCutoff,
                    color: AppColors.riskYellow.withValues(alpha: 0.10),
                  ),
                  HorizontalRangeAnnotation(
                    y1: CalculateFib4.highCutoff,
                    y2: maxY,
                    color: AppColors.riskRed.withValues(alpha: 0.10),
                  ),
                ],
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
                    _isMeter
                        ? '${value.round()}%'
                        : formatScore(value).replaceAll(',00', ''),
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
                  '${_isMeter ? 'Medidor ${spot.y.round()}%' : 'FIB-4 ${formatScore(spot.y)}'}',
                  AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(xs[i], _valueOf(points[i])),
            ],
            color: AppColors.textPrimary,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                radius: 5,
                color: points[index].risk.color,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
