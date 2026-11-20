import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class BodyRiskFigure extends StatelessWidget {
  const BodyRiskFigure({
    super.key,
    required this.liverColor,
    required this.child,
    this.progress = kAlwaysCompleteAnimation,
  });

  static const contourAsset = 'assets/images/contorno.svg';
  static const organsAsset = 'assets/images/orgaos.svg';
  static const liverAsset = 'assets/images/figado.svg';
  static const aspectRatio = 368 / 698;
  static const cardTop = 0.43;
  static const bodyOpacity = 0.7;
  static const cardOpacity = 0.85;
  static const cardBlur = 8.0;
  static const neutralLiver = Color(0xFF9E9E9E);

  static const contourInterval = Interval(0, 0.2, curve: Curves.easeOut);
  static const scanInterval = Interval(0.2, 0.8, curve: Curves.easeInOut);
  static const revealInterval = Interval(0.8, 1, curve: Curves.easeOut);

  final Color? liverColor;
  final Widget child;
  final Animation<double> progress;

  static Future<void> precache(BuildContext context, Color? liverColor) =>
      Future.wait([
        for (final loader in [
          const SvgAssetLoader(contourAsset),
          const SvgAssetLoader(organsAsset),
          const SvgAssetLoader(
            liverAsset,
            colorMapper: LiverColorMapper(neutralLiver),
          ),
          SvgAssetLoader(
            liverAsset,
            colorMapper: LiverColorMapper(
              liverColor ?? AppColors.textSecondary,
            ),
          ),
        ])
          loader.loadBytes(context),
      ]);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 420.0);
        final height = width / aspectRatio;
        final color = liverColor ?? AppColors.textSecondary;
        final reveal = CurvedAnimation(parent: progress, curve: revealInterval);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) =>
                      _figure(progress.value, height, color),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: height * cardTop),
              child: FadeTransition(
                opacity: reveal,
                alwaysIncludeSemantics: true,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(reveal),
                  child: _frosted(context, child),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _frosted(BuildContext context, Widget card) {
    final theme = Theme.of(context);
    final background = theme.cardTheme.color ?? AppColors.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: cardBlur, sigmaY: cardBlur),
        child: Theme(
          data: theme.copyWith(
            cardTheme: theme.cardTheme.copyWith(
              color: background.withValues(alpha: cardOpacity),
              margin: EdgeInsets.zero,
            ),
          ),
          child: card,
        ),
      ),
    );
  }

  Widget _figure(double t, double height, Color color) {
    final contour = contourInterval.transform(t);
    final scan = scanInterval.transform(t);
    final reveal = revealInterval.transform(t);
    final scanning = t > scanInterval.begin && t < scanInterval.end;

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: bodyOpacity * contour,
          child: SvgPicture.asset(contourAsset),
        ),
        ClipRect(
          clipper: _RevealClipper(scan),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: bodyOpacity,
                child: SvgPicture.asset(organsAsset),
              ),
              Opacity(
                opacity: 1 - reveal,
                child: SvgPicture.asset(
                  liverAsset,
                  colorMapper: const LiverColorMapper(neutralLiver),
                ),
              ),
            ],
          ),
        ),
        Opacity(
          opacity: reveal,
          child: SvgPicture.asset(
            liverAsset,
            colorMapper: LiverColorMapper(color),
          ),
        ),
        if (scanning)
          Positioned(
            top: scan * height - 12,
            left: 0,
            right: 0,
            height: 24,
            child: const _ScanLine(),
          ),
      ],
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.olive.withValues(alpha: 0),
                AppColors.olive.withValues(alpha: 0.35),
                AppColors.olive.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.olive.withValues(alpha: 0),
                const Color(0xFFB4C96A),
                AppColors.olive.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
class LiverColorMapper extends ColorMapper {
  const LiverColorMapper(this.color);

  static const _light = Color(0xFFFFEE00);
  static const _dark = Color(0xFF636001);

  final Color color;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color original,
  ) {
    if (original == _light) return color;
    if (original == _dark) return Color.lerp(color, Colors.black, 0.6)!;
    return original;
  }

  @override
  bool operator ==(Object other) =>
      other is LiverColorMapper && other.color == color;

  @override
  int get hashCode => color.hashCode;
}
