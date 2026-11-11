import 'package:flutter/material.dart';

import '../camouflage/calculator_engine.dart';

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
    ['C', '±', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['0', ',', '='],
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
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Semantics(
                    label: 'Visor da calculadora',
                    child: Text(
                      _engine.display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: const Color(0xFF1B1B1B),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (final (rowIndex, row) in _rows.indexed) ...[
                      if (rowIndex > 0) const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            for (final (keyIndex, key) in row.indexed) ...[
                              if (keyIndex > 0) const SizedBox(width: 12),
                              Expanded(
                                flex: key == '0' ? 2 : 1,
                                child: _CalculatorButton(
                                  label: key,
                                  highlighted: _operators.contains(key),
                                  onPressed: () => _press(key),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.highlighted,
    required this.onPressed,
  });

  final String label;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tecla $label',
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: highlighted
              ? const Color(0xFF3D3D3D)
              : const Color(0xFFE6E6E6),
          foregroundColor: highlighted ? Colors.white : const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
