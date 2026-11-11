import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Medidor de saúde do fígado (0 a 100%), em semicírculo.
///
/// O [value] vem do caso de uso `CalculateLiverHealth` (FIB-4 e consumo) e a
/// cor segue a faixa de risco.
class LiverGauge extends StatelessWidget {
  const LiverGauge({
    super.key,
    required this.value,
    required this.color,
    this.size = 220,
  }) : assert(value >= 0 && value <= 100);

  /// Saúde do fígado, de 0 a 100.
  final double value;

  /// Cor do semáforo de risco (verde, amarelo ou vermelho).
  final Color color;

  /// Largura do medidor; a altura é metade disso mais o espaço do texto.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Medidor de saúde do fígado: ${value.round()} por cento',
      child: SizedBox(
        width: size,
        height: size * 0.62,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GaugePainter(value: value / 100, color: color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${value.round()}%', style: AppTextStyles.display),
                const Text('saúde do fígado', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  static const _stroke = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - _stroke / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.width / 2),
      radius: radius,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceVariant;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(rect, math.pi, math.pi * value, false, progress);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}
