import 'package:flutter/material.dart';

import '../../domain/entities/risk_level.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = riskLevel.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskLevel.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            riskLevel.label.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
