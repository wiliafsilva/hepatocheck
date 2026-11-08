import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'liver_gauge.dart';

/// Cartão de risco da tela Início: idade, FIB-4, selo de risco e medidor.
///
/// Os dados são recebidos de fora; por enquanto a tela Início passa valores
/// fixos, que serão trocados pelos dados reais do último exame.
class RiskCard extends StatelessWidget {
  const RiskCard({
    super.key,
    required this.age,
    required this.fib4,
    required this.riskLabel,
    required this.riskColor,
    required this.gaugeValue,
  });

  final int age;
  final String fib4;
  final String riskLabel;
  final Color riskColor;
  final double gaugeValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Idade: $age', style: AppTextStyles.body),
                      Text('FIB-4: $fib4', style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _RiskBadge(label: riskLabel, color: riskColor),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LiverGauge(value: gaugeValue, color: riskColor),
            const SizedBox(height: 16),
            const Text(
              'Indicador educativo, não é um resultado clínico. '
              'O app não substitui diagnóstico médico.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
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

/// Atalho para as cores do semáforo, usado enquanto o domínio não existe.
abstract final class RiskPalette {
  static const green = AppColors.riskGreen;
  static const yellow = AppColors.riskYellow;
  static const red = AppColors.riskRed;
}
