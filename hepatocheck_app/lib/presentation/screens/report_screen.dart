import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/consumption_report.dart';
import '../../domain/entities/drink_type.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/report_period.dart';
import '../formatters.dart';
import '../providers/exam_providers.dart';
import '../providers/report_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import '../widgets/delta_label.dart';
import '../widgets/risk_badge.dart';
import '../widgets/section_label.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final periodNotifier = ref.read(reportPeriodProvider.notifier);
    final report = ref.watch(consumptionReportProvider);
    final exams = ref.watch(examsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        SegmentedButton<ReportPeriodType>(
          segments: const [
            ButtonSegment(
              value: ReportPeriodType.week,
              label: Text('Semana'),
              icon: Icon(Icons.view_week_outlined),
            ),
            ButtonSegment(
              value: ReportPeriodType.month,
              label: Text('Mês'),
              icon: Icon(Icons.calendar_month_outlined),
            ),
          ],
          selected: {period.type},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              periodNotifier.selectType(selection.first),
        ),
        const SizedBox(height: 12),
        _PeriodNavigator(
          label: formatPeriod(period),
          onPrevious: periodNotifier.previous,
          onNext: periodNotifier.canGoNext ? periodNotifier.next : null,
        ),
        const SizedBox(height: 20),
        const SectionLabel('RISCO ATUAL'),
        const SizedBox(height: 8),
        _CurrentRiskCard(latest: exams.isEmpty ? null : exams.first),
        const SizedBox(height: 24),
        const SectionLabel('RESUMO DO CONSUMO'),
        const SizedBox(height: 8),
        _SummaryGrid(report: report, type: period.type),
        const SizedBox(height: 24),
        const SectionLabel('CONSUMO POR TIPO DE BEBIDA'),
        const SizedBox(height: 8),
        _ByTypeCard(report: report),
        const SizedBox(height: 16),
        const Text(
          'Triagem preventiva. Não substitui avaliação médica.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Período anterior',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
        ),
        IconButton(
          tooltip: 'Próximo período',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _CurrentRiskCard extends ConsumerWidget {
  const _CurrentRiskCard({required this.latest});

  final LabExam? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = latest;
    if (exam == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.biotech_outlined, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registre um exame na aba Exames para ver seu risco.',
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final result = ref.watch(calculateFib4Provider)(exam);
    final color = result.riskLevel.color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FIB-4', style: AppTextStyles.caption),
                      Text(
                        formatScore(result.score),
                        style: AppTextStyles.title.copyWith(color: color),
                      ),
                      Text(
                        'Exame de ${formatDate(exam.examDate)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                RiskBadge(riskLevel: result.riskLevel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.riskLevel.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report, required this.type});

  final ConsumptionReport? report;
  final ReportPeriodType type;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final previousLabel = type == ReportPeriodType.week
        ? 'semana anterior'
        : 'mês anterior';

    final cards = [
      _SummaryCard(
        icon: Icons.local_bar_outlined,
        title: 'Drinques padrão',
        value: report == null ? '—' : formatDrinks(report.totalStandardDrinks),
      ),
      _SummaryCard(
        icon: Icons.today_outlined,
        title: 'Média por dia',
        value: report == null ? '—' : formatDrinks(report.averagePerDay),
      ),
      _SummaryCard(
        icon: Icons.event_available_outlined,
        title: 'Dias sem álcool',
        value: report == null
            ? '—'
            : '${report.alcoholFreeDays} de ${report.elapsedDays}',
      ),
      _SummaryCard(
        icon: Icons.compare_arrows,
        title: 'Vs. $previousLabel',
        value: report == null ? '—' : _differenceText(report),
        footer: report == null || report.difference == 0
            ? null
            : DeltaLabel(delta: report.difference, text: _percentText(report)),
      ),
    ];

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: cards,
        ),
        if (report == null || !report.hasData)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Nenhum drinque registrado neste período.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }

  static String _differenceText(ConsumptionReport report) {
    final difference = report.difference;
    if (difference == 0) return 'Igual';
    final sign = difference > 0 ? '+' : '−';
    return '$sign${formatDrinks(difference.abs())}';
  }

  static String _percentText(ConsumptionReport report) {
    final percent = report.changePercent;
    if (percent == null) return 'sem consumo antes';
    return '${percent.abs().round()}%';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.olive),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(value, style: AppTextStyles.title),
            ?footer,
          ],
        ),
      ),
    );
  }
}

class _ByTypeCard extends StatelessWidget {
  const _ByTypeCard({required this.report});

  final ConsumptionReport? report;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final entries = report == null
        ? <MapEntry<DrinkType, double>>[]
        : (report.byType.entries.where((entry) => entry.value > 0).toList()
            ..sort((a, b) => b.value.compareTo(a.value)));

    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'O consumo por tipo aparece quando houver registros no período.',
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    final highest = entries.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final (index, entry) in entries.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              _TypeBar(
                label: _drinkTypeLabel(entry.key),
                value: entry.value,
                fraction: entry.value / highest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeBar extends StatelessWidget {
  const _TypeBar({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final double value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.label)),
            Text(formatDrinks(value), style: AppTextStyles.label),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            color: AppColors.olive,
            backgroundColor: AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _drinkTypeLabel(DrinkType type) => switch (type) {
  DrinkType.beer => 'Cerveja',
  DrinkType.wine => 'Vinho',
  DrinkType.spirit => 'Destilado',
  DrinkType.cocktail => 'Drinque / coquetel',
  DrinkType.other => 'Outros',
};
