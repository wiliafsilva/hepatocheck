import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/risk_level.dart';
import '../../domain/usecases/assess_current_risk.dart';
import '../../domain/usecases/build_consultation_summary.dart';
import '../../domain/usecases/build_exam_evolution.dart';
import '../../domain/usecases/summarize_exam_history.dart';
import '../formatters.dart';
import '../providers/consultation_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import '../widgets/content_width.dart';
import '../widgets/risk_badge.dart';
import '../widgets/section_label.dart';

class ConsultationScreen extends ConsumerWidget {
  const ConsultationScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const ConsultationScreen(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(consultationSummaryProvider);
    final risk = summary.risk;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Modo consulta', style: AppTextStyles.display),
                        SizedBox(height: 4),
                        Text(
                          'Resumo para o profissional de saúde · dados '
                          'informados pelo paciente',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Fechar o modo consulta',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (risk == null)
                const _EmptyRiskCard()
              else
                _RiskCard(risk: risk),
              const SizedBox(height: 14),
              _ConsumptionCard(summary: summary),
              if (summary.recentExams.length >= 2) ...[
                const SizedBox(height: 14),
                _EvolutionCard(summary: summary),
              ],
              const SizedBox(height: 20),
              const Text(
                'Triagem preventiva baseada em dados informados pelo '
                'paciente. Não substitui a avaliação clínica.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Sair do modo consulta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [SectionLabel(title), ?trailing],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyRiskCard extends StatelessWidget {
  const _EmptyRiskCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'CLASSIFICAÇÃO DE RISCO',
      child: Text(
        'Nenhum exame registrado. O FIB-4 aparece depois do primeiro exame '
        'na aba Exames.',
        style: AppTextStyles.body,
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.risk});

  final CurrentRisk risk;

  static String _band(RiskLevel level) => switch (level) {
    RiskLevel.low => 'Faixa baixa',
    RiskLevel.intermediate => 'Faixa intermediária',
    RiskLevel.high => 'Faixa alta',
  };

  @override
  Widget build(BuildContext context) {
    final exam = risk.exam;
    final fib4 = risk.fib4;
    final color = fib4.riskLevel.color;
    return _Panel(
      title: 'CLASSIFICAÇÃO DE RISCO',
      trailing: RiskBadge(riskLevel: risk.level),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                formatScore(fib4.score),
                style: AppTextStyles.display.copyWith(
                  color: color,
                  fontSize: 48,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FIB-4 atual', style: AppTextStyles.subtitle),
                  Text(
                    _band(fib4.riskLevel),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _Value(label: 'Idade', value: '${exam.age}', unit: 'anos'),
              _Value(
                label: 'AST/TGO',
                value: formatNumber(exam.ast),
                unit: 'U/L',
              ),
              _Value(
                label: 'ALT/TGP',
                value: formatNumber(exam.alt),
                unit: 'U/L',
              ),
              _Value(
                label: 'Plaquetas',
                value: formatNumber(exam.platelets),
                unit: '×10³',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Exame de ${formatDate(exam.examDate)}',
            style: AppTextStyles.caption,
          ),
          if (fib4.ageOutsideValidatedRange) ...[
            const SizedBox(height: 6),
            Text(
              'Idade fora da faixa validada do FIB-4 (35 a 65 anos).',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.riskYellow,
              ),
            ),
          ],
          if (risk.raisedByConsumption) ...[
            const SizedBox(height: 6),
            Text(
              'Nível elevado para ${risk.level.label}: o consumo da semana '
              'atual (${formatDrinks(risk.weeklyStandardDrinks)} drinques '
              'padrão) passou da meta de ${risk.weeklyLimit} definida pelo '
              'paciente.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value, style: AppTextStyles.title),
              TextSpan(text: ' $unit', style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsumptionCard extends StatelessWidget {
  const _ConsumptionCard({required this.summary});

  final ConsultationSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasDiary) {
      return const _Panel(
        title: 'CONSUMO DE ÁLCOOL',
        child: Text(
          'Nenhum registro no diário de consumo.',
          style: AppTextStyles.body,
        ),
      );
    }
    return _Panel(
      title: 'CONSUMO DE ÁLCOOL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                formatDrinks(summary.weeklyAverage),
                style: AppTextStyles.display.copyWith(fontSize: 48),
              ),
              const Text(
                'drinques padrão por semana',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Média dos últimos ${summary.windowDays} dias · '
            '${summary.alcoholFreeDays} dias sem álcool',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Um drinque padrão equivale a 14 g de álcool puro.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.summary});

  final ConsultationSummary summary;

  @override
  Widget build(BuildContext context) {
    final points = summary.recentExams;
    final delta = summary.recentDelta!;
    final trend = summary.recentTrend!;
    final since = formatMonthName(points.first.date);
    final (color, icon, text) = switch (trend) {
      Fib4Trend.improved => (
        AppColors.riskGreen,
        Icons.arrow_downward,
        'Queda de ${formatScore(delta.abs())} desde $since',
      ),
      Fib4Trend.worsened => (
        AppColors.riskRed,
        Icons.arrow_upward,
        'Alta de ${formatScore(delta.abs())} desde $since',
      ),
      Fib4Trend.stable => (
        AppColors.textSecondary,
        Icons.arrow_forward,
        'Estável desde $since',
      ),
    };

    return _Panel(
      title: 'EVOLUÇÃO DO FIB-4',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final (index, point) in points.indexed) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                Expanded(child: _ScorePoint(point: point)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.label.copyWith(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePoint extends StatelessWidget {
  const _ScorePoint({required this.point});

  final ExamPoint point;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatScore(point.fib4.score),
            style: AppTextStyles.title.copyWith(
              color: point.fib4.riskLevel.color,
            ),
          ),
        ),
        Text(
          formatMonthYear(point.date),
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
