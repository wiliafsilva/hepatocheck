import 'package:flutter/material.dart';

import '../../domain/usecases/calculate_liver_health.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';
import 'liver_gauge.dart';

/// Cartão de risco da tela Início: idade, FIB-4, selo de risco e medidor,
/// calculados a partir do exame mais recente e do consumo.
class RiskCard extends StatelessWidget {
  const RiskCard({super.key, required this.health});

  final LiverHealth health;

  @override
  Widget build(BuildContext context) {
    final exam = health.exam;
    final risk = health.risk;
    final fib4 = health.fib4;
    final color = risk?.color ?? AppColors.outline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (exam != null && risk != null && fib4 != null) ...[
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Idade: ${exam.age}', style: AppTextStyles.body),
                        Text(
                          'FIB-4: ${_formatFib4(fib4)}',
                          style: AppTextStyles.subtitle,
                        ),
                      ],
                    ),
                    _RiskBadge(
                      label: 'Risco ${risk.label.toLowerCase()}',
                      color: color,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            LiverGauge(value: health.percent ?? 0, color: color),
            const SizedBox(height: 16),
            Text(
              exam == null
                  ? 'Registre um exame na aba Exames para ver o medidor '
                        'do seu fígado.'
                  : 'Indicador educativo, não é um resultado clínico. '
                        'O app não substitui diagnóstico médico.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFib4(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }
}
