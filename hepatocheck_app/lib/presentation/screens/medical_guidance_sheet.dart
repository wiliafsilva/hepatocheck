import 'package:flutter/material.dart';

import '../../domain/entities/risk_level.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';

/// Abre a orientação educativa do RF14 sem tirar o usuário da tela atual.
Future<void> showMedicalGuidance(
  BuildContext context, {
  RiskLevel? currentRisk,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: MedicalGuidanceSheet(currentRisk: currentRisk),
    ),
  );
}

class MedicalGuidanceSheet extends StatelessWidget {
  const MedicalGuidanceSheet({super.key, this.currentRisk});

  final RiskLevel? currentRisk;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Quando procurar o médico',
                  style: AppTextStyles.title,
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'O FIB-4 ajuda na triagem do risco hepático. Ele não confirma '
            'diagnósticos e não substitui uma avaliação profissional.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 20),
          _GuidanceCard(
            risk: RiskLevel.low,
            selected: currentRisk == RiskLevel.low,
            guidance:
                'Mantenha hábitos saudáveis e repita os exames no intervalo '
                'orientado pelo profissional que acompanha sua saúde.',
          ),
          const SizedBox(height: 12),
          _GuidanceCard(
            risk: RiskLevel.intermediate,
            selected: currentRisk == RiskLevel.intermediate,
            guidance:
                'Converse com um gastroenterologista ou hepatologista para '
                'avaliar o resultado e definir o acompanhamento adequado.',
          ),
          const SizedBox(height: 12),
          _GuidanceCard(
            risk: RiskLevel.high,
            selected: currentRisk == RiskLevel.high,
            guidance:
                'Procure um gastroenterologista ou hepatologista para uma '
                'avaliação clínica do resultado.',
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.olive),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Leve seus exames e o resumo do aplicativo à consulta. '
                      'A decisão sobre diagnóstico e tratamento cabe ao '
                      'profissional de saúde.',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.risk,
    required this.selected,
    required this.guidance,
  });

  final RiskLevel risk;
  final bool selected;
  final String guidance;

  @override
  Widget build(BuildContext context) {
    final color = risk.color;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? color : AppColors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(risk.icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Risco ${risk.label.toLowerCase()}',
                    style: AppTextStyles.subtitle.copyWith(color: color),
                  ),
                ),
                if (selected)
                  const Text('Seu resultado', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(_meaning, style: AppTextStyles.body),
            const SizedBox(height: 8),
            Text(guidance, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  String get _meaning => switch (risk) {
    RiskLevel.low => 'Seus dados estão na faixa de menor risco.',
    RiskLevel.intermediate =>
      'Seus dados estão na faixa de risco intermediário.',
    RiskLevel.high => 'Seus dados estão na faixa de maior risco.',
  };
}
