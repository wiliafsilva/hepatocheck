import 'package:flutter/material.dart';

import '../../domain/entities/fib4_result.dart';
import '../../domain/usecases/summarize_exam_history.dart';
import '../formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';

class Fib4EvolutionSummary extends StatelessWidget {
  const Fib4EvolutionSummary({super.key, required this.summary});

  final ExamHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (summary.trend) {
      Fib4Trend.improved => (
        'Melhorou',
        AppColors.riskGreen,
        Icons.trending_down,
      ),
      Fib4Trend.worsened => ('Piorou', AppColors.riskRed, Icons.trending_up),
      Fib4Trend.stable => (
        'Estável',
        AppColors.textSecondary,
        Icons.trending_flat,
      ),
    };
    final sign = summary.delta > 0
        ? '+'
        : summary.delta < 0
        ? '−'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Evolução do FIB-4', style: AppTextStyles.body),
                ),
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label, style: AppTextStyles.label.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScoreAtDate(
                    title: 'Primeiro',
                    result: summary.first,
                    date: summary.firstDate,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                Expanded(
                  child: _ScoreAtDate(
                    title: 'Último',
                    result: summary.latest,
                    date: summary.latestDate,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Variação de $sign${formatScore(summary.delta.abs())} em '
              '${summary.examCount} exames. Último exame '
              '${formatElapsedDays(summary.daysSinceLatest)}.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreAtDate extends StatelessWidget {
  const _ScoreAtDate({
    required this.title,
    required this.result,
    required this.date,
    this.alignEnd = false,
  });

  final String title;
  final Fib4Result result;
  final DateTime date;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption),
        Text(
          formatScore(result.score),
          style: AppTextStyles.subtitle.copyWith(color: result.riskLevel.color),
        ),
        Text(formatDate(date), style: AppTextStyles.caption),
      ],
    );
  }
}
