import 'package:flutter/material.dart';

import '../../domain/entities/risk_level.dart';
import '../theme/app_text_styles.dart';
import '../theme/risk_colors.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel, this.onTap});

  final RiskLevel riskLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = riskLevel.color;
    final badge = Container(
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
    if (onTap == null) return badge;
    return Semantics(
      button: true,
      label:
          'Risco ${riskLevel.label.toLowerCase()}. Abrir orientação sobre '
          'quando procurar o médico.',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: badge,
      ),
    );
  }
}
