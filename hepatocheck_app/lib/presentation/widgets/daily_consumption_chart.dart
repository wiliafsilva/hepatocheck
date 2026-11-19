import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/consumption_report.dart';
import '../../domain/entities/report_period.dart';
import '../formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const _weekdayInitials = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

class DailyConsumptionChart extends StatelessWidget {
  const DailyConsumptionChart({super.key, required this.report});

  final ConsumptionReport report;

  @override
  Widget build(BuildContext context) {
    final daily = report.daily;
    if (!report.hasData || daily.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'O consumo por dia aparece quando houver registros no período.',
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    final isWeek = report.period.type == ReportPeriodType.week;
    final highest = daily
        .map((day) => day.standardDrinks)
        .reduce((a, b) => a > b ? a : b);
    final maxY = highest <= 0 ? 1.0 : highest * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: _semanticSummary(daily),
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.outline,
                          strokeWidth: 1,
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceVariant,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                            '${formatDayMonth(daily[group.x].day)}\n'
                            '${formatDrinks(rod.toY)} drinques',
                            AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  formatNumber(value),
                                  style: AppTextStyles.caption,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              final day = daily[index].day;
                              final show =
                                  isWeek || day.day == 1 || day.day % 5 == 0;
                              if (!show) return const SizedBox.shrink();
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  isWeek
                                      ? _weekdayInitials[day.weekday - 1]
                                      : '${day.day}',
                                  style: AppTextStyles.caption,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (final (index, day) in daily.indexed)
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: day.standardDrinks,
                                width: isWeek ? 18 : 6,
                                color: AppColors.olive,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drinques padrão por dia (14 g de álcool cada).',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  static String _semanticSummary(List<DailyConsumption> daily) {
    final withDrinks = daily.where((day) => day.standardDrinks > 0);
    final parts = [
      for (final day in withDrinks)
        '${formatDayMonth(day.day)}: ${formatDrinks(day.standardDrinks)}',
    ];
    return 'Gráfico do consumo por dia. Dias com consumo: ${parts.join(', ')}.';
  }
}
