import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DeltaLabel extends StatelessWidget {
  const DeltaLabel({super.key, required this.delta, required this.text});

  final double delta;
  final String text;

  @override
  Widget build(BuildContext context) {
    final improved = delta < 0;
    final color = delta == 0
        ? AppColors.textSecondary
        : improved
        ? AppColors.riskGreen
        : AppColors.riskRed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (delta != 0)
          Icon(
            improved ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14,
            color: color,
          ),
        if (delta != 0) const SizedBox(width: 2),
        Text(text, style: AppTextStyles.caption.copyWith(color: color)),
      ],
    );
  }
}
