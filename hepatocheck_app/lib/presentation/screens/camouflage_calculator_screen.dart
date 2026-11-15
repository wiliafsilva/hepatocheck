import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../camouflage/calculator_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CamouflageCalculatorScreen extends StatefulWidget {
  const CamouflageCalculatorScreen({
    required this.onSecretCodeAttempt,
    super.key,
  });

  final Future<bool> Function(String code) onSecretCodeAttempt;

  @override
  State<CamouflageCalculatorScreen> createState() =>
      _CamouflageCalculatorScreenState();
}

class _CamouflageCalculatorScreenState
    extends State<CamouflageCalculatorScreen> {
  static const _rows = <List<String>>[
    ['C', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['()', '0', ',', '='],
  ];
  static const _operators = {'÷', '×', '−', '+', '='};

  final _engine = CalculatorEngine();
  String _secretAttempt = '';
  bool _checkingCode = false;

  Future<void> _press(String key) async {
    setState(() => _engine.press(key));

    if ('0123456789'.contains(key)) {
      _secretAttempt += key;
      if (_secretAttempt.length < 4 || _checkingCode) return;

      _checkingCode = true;
      final maximumLength = _secretAttempt.length.clamp(4, 8);
      var isSecretCode = false;
      for (var length = 4; length <= maximumLength; length++) {
        final candidate = _secretAttempt.substring(
          _secretAttempt.length - length,
        );
        if (await widget.onSecretCodeAttempt(candidate)) {
          isSecretCode = true;
          break;
        }
      }
      _checkingCode = false;
      if (!mounted) return;
      if (isSecretCode) return;
      _secretAttempt = _secretAttempt.length > 8
          ? _secretAttempt.substring(_secretAttempt.length - 8)
          : _secretAttempt;
      return;
    }

    _secretAttempt = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final keySize = math.min(
                    (constraints.maxWidth - spacing * 3) / 4,
                    (constraints.maxHeight - 130 - spacing * 4) / 5,
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomRight,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _engine.expression,
                                      key: const ValueKey(
                                        'calculator-expression',
                                      ),
                                      maxLines: 1,
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    label: 'Visor da calculadora',
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _engine.display,
                                        key: const ValueKey(
                                          'calculator-result',
                                        ),
                                        maxLines: 1,
                                        style: AppTextStyles.display.copyWith(
                                          fontSize: 64,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (final (rowIndex, row) in _rows.indexed) ...[
                        if (rowIndex > 0) const SizedBox(height: spacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final (columnIndex, key) in row.indexed) ...[
                              if (columnIndex > 0)
                                const SizedBox(width: spacing),
                              SizedBox.square(
                                dimension: keySize,
                                child: _CalculatorButton(
                                  label: key,
                                  style: _buttonStyleFor(key),
                                  onPressed: () => _press(key),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  _CalculatorKeyStyle _buttonStyleFor(String key) {
    if (_operators.contains(key)) return _CalculatorKeyStyle.operator;
    if (key == String.fromCharCode(0x232B)) {
      return _CalculatorKeyStyle.function;
    }
    if (key == 'C' || key == '()' || key == '%') {
      return _CalculatorKeyStyle.function;
    }
    return _CalculatorKeyStyle.number;
  }
}

enum _CalculatorKeyStyle { number, function, operator }

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final _CalculatorKeyStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isFunction = style == _CalculatorKeyStyle.function;
    final backgroundColor = switch (style) {
      _CalculatorKeyStyle.number => AppColors.surface,
      _CalculatorKeyStyle.function => AppColors.surfaceVariant,
      _CalculatorKeyStyle.operator => AppColors.surface,
    };
    final foregroundColor = label == 'C'
        ? AppColors.riskRed
        : label == '='
        ? AppColors.onOlive
        : style == _CalculatorKeyStyle.operator
        ? AppColors.olive
        : AppColors.textPrimary;
    final isEquals = label == '=';

    return Semantics(
      button: true,
      label: label == '⌫' ? 'Apagar último dígito' : 'Tecla $label',
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isEquals ? AppColors.olive : backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: label == '⌫'
                ? const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textPrimary,
                    size: 26,
                  )
                : Text(
                    label,
                    style: AppTextStyles.title.copyWith(
                      color: foregroundColor,
                      fontSize: isFunction ? 22 : 28,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
