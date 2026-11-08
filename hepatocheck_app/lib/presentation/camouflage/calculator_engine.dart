/// Estado e operações de uma calculadora simples, sem dependência de Flutter.
class CalculatorEngine {
  String _display = '0';
  double? _leftOperand;
  String? _operator;
  bool _replaceDisplay = true;

  String get display => _display.replaceAll('.', ',');

  void press(String key) {
    if ('0123456789'.contains(key)) {
      _addDigit(key);
      return;
    }

    switch (key) {
      case ',':
        _addDecimalSeparator();
        return;
      case 'C':
        clear();
        return;
      case '±':
        _toggleSign();
        return;
      case '%':
        _display = (_asNumber() / 100).toString();
        _replaceDisplay = true;
        return;
      case '÷':
      case '×':
      case '−':
      case '+':
        _setOperator(key);
        return;
      case '=':
        _calculate();
        return;
    }
  }

  void clear() {
    _display = '0';
    _leftOperand = null;
    _operator = null;
    _replaceDisplay = true;
  }

  void _addDigit(String digit) {
    if (_replaceDisplay) {
      _display = digit;
      _replaceDisplay = false;
      return;
    }
    _display = _display == '0' ? digit : '$_display$digit';
  }

  void _addDecimalSeparator() {
    if (_replaceDisplay) {
      _display = '0.';
      _replaceDisplay = false;
      return;
    }
    if (!_display.contains('.')) _display = '$_display.';
  }

  void _toggleSign() {
    if (_display == '0') return;
    _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
  }

  void _setOperator(String nextOperator) {
    if (_leftOperand != null && _operator != null && !_replaceDisplay) {
      _calculate();
    }
    _leftOperand ??= _asNumber();
    _operator = nextOperator;
    _replaceDisplay = true;
  }

  void _calculate() {
    if (_leftOperand == null || _operator == null) return;

    final rightOperand = _asNumber();
    final result = switch (_operator!) {
      '+' => _leftOperand! + rightOperand,
      '−' => _leftOperand! - rightOperand,
      '×' => _leftOperand! * rightOperand,
      '÷' => rightOperand == 0 ? null : _leftOperand! / rightOperand,
      _ => null,
    };

    _display = result == null ? 'Erro' : _format(result);
    _leftOperand = null;
    _operator = null;
    _replaceDisplay = true;
  }

  double _asNumber() => double.tryParse(_display) ?? 0;

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return 'Erro';
    return value == value.truncateToDouble()
        ? value.truncate().toString()
        : value
              .toStringAsFixed(8)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
  }
}
