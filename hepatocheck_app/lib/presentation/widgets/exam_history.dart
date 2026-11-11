import 'package:flutter/material.dart';

import '../../domain/entities/fib4_result.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/usecases/calculate_fib4.dart';
import '../../domain/usecases/summarize_exam_history.dart';
import '../formatters.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import 'delta_label.dart';

class ExamHistory extends StatefulWidget {
  const ExamHistory({
    super.key,
    required this.exams,
    required this.calculate,
    required this.summary,
    required this.selectedId,
    required this.onEdit,
    required this.onDelete,
  });

  static const collapsedCount = 5;

  final List<LabExam> exams;
  final CalculateFib4 calculate;
  final ExamHistorySummary? summary;
  final String? selectedId;
  final ValueChanged<LabExam> onEdit;
  final ValueChanged<LabExam> onDelete;

  @override
  State<ExamHistory> createState() => _ExamHistoryState();
}

class _ExamHistoryState extends State<ExamHistory> {
  bool _showAll = false;
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final exams = widget.exams;
    if (exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Nenhum exame registrado ainda.',
          style: AppTextStyles.body,
        ),
      );
    }

    final summary = widget.summary;
    final hasMore = exams.length > ExamHistory.collapsedCount;
    final visibleCount = _showAll || !hasMore
        ? exams.length
        : ExamHistory.collapsedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null && summary.examCount >= 2) ...[
          _EvolutionSummary(summary: summary),
          const SizedBox(height: 12),
        ],
        for (var index = 0; index < visibleCount; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoryTile(
              exam: exams[index],
              result: widget.calculate(exams[index]),
              previous: index + 1 < exams.length
                  ? widget.calculate(exams[index + 1])
                  : null,
              selected: widget.selectedId == exams[index].id,
              expanded: _expandedId == exams[index].id,
              onToggle: () => setState(() {
                final id = exams[index].id;
                _expandedId = _expandedId == id ? null : id;
              }),
              onEdit: () => widget.onEdit(exams[index]),
              onDelete: () => widget.onDelete(exams[index]),
            ),
          ),
        if (hasMore)
          Align(
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _showAll ? 'Ver menos' : 'Ver todos (${exams.length})',
              ),
            ),
          ),
      ],
    );
  }
}

class _EvolutionSummary extends StatelessWidget {
  const _EvolutionSummary({required this.summary});

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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.exam,
    required this.result,
    required this.previous,
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final LabExam exam;
  final Fib4Result result;
  final Fib4Result? previous;
  final bool selected;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel.color;
    final previousScore = previous?.score;
    final delta = previousScore == null
        ? null
        : double.parse((result.score - previousScore).toStringAsFixed(2));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.olive : AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatScore(result.score),
                      style: AppTextStyles.label.copyWith(color: color),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(exam.examDate),
                          style: AppTextStyles.subtitle,
                        ),
                        Text.rich(
                          TextSpan(
                            text: 'Faixa: ',
                            style: AppTextStyles.caption,
                            children: [
                              TextSpan(
                                text: result.riskLevel.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (delta != null && delta != 0)
                    DeltaLabel(delta: delta, text: formatScore(delta.abs())),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  IconButton(
                    tooltip: 'Excluir exame',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.riskRed,
                    ),
                  ),
                ],
              ),
              if (expanded)
                _ExamDetails(exam: exam, result: result, onEdit: onEdit),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamDetails extends StatelessWidget {
  const _ExamDetails({
    required this.exam,
    required this.result,
    required this.onEdit,
  });

  final LabExam exam;
  final Fib4Result result;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.outline),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _DetailItem(label: 'Idade', value: '${exam.age} anos'),
              _DetailItem(
                label: 'AST / TGO',
                value: '${formatNumber(exam.ast)} U/L',
              ),
              _DetailItem(
                label: 'ALT / TGP',
                value: '${formatNumber(exam.alt)} U/L',
              ),
              _DetailItem(
                label: 'Plaquetas',
                value: '${formatNumber(exam.platelets)} ×10³/mm³',
              ),
            ],
          ),
          if (result.ageOutsideValidatedRange) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.riskYellow,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Idade fora da faixa validada do FIB-4 (35 a 65 anos).',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.riskYellow,
                    ),
                  ),
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(value, style: AppTextStyles.label),
      ],
    );
  }
}
