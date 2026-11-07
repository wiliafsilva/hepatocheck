import 'package:flutter/material.dart';

import '../../domain/entities/risk_level.dart';
import 'app_colors.dart';

extension RiskLevelColors on RiskLevel {
  Color get color => switch (this) {
    RiskLevel.low => AppColors.riskGreen,
    RiskLevel.intermediate => AppColors.riskYellow,
    RiskLevel.high => AppColors.riskRed,
  };

  String get label => switch (this) {
    RiskLevel.low => 'Verde',
    RiskLevel.intermediate => 'Amarelo',
    RiskLevel.high => 'Vermelho',
  };

  IconData get icon => switch (this) {
    RiskLevel.low => Icons.check_circle_outline,
    RiskLevel.intermediate => Icons.warning_amber_rounded,
    RiskLevel.high => Icons.error_outline,
  };

  String get description => switch (this) {
    RiskLevel.low =>
      'Faixa baixa. Mantenha hábitos saudáveis e repita o exame '
          'conforme orientação médica.',
    RiskLevel.intermediate =>
      'Faixa intermediária (1,30 a 2,67). Converse com um '
          'gastroenterologista.',
    RiskLevel.high =>
      'Faixa alta (acima de 2,67). Procure um hepatologista ou '
          'gastroenterologista.',
  };
}
