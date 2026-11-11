import 'package:flutter/material.dart';

import '../../domain/entities/risk_level.dart';
import 'app_colors.dart';

extension RiskLevelColor on RiskLevel {
  Color get color => switch (this) {
    RiskLevel.low => AppColors.riskGreen,
    RiskLevel.intermediate => AppColors.riskYellow,
    RiskLevel.high => AppColors.riskRed,
  };
}
