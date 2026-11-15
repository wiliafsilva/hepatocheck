/// Estado e operações de uma calculadora simples, sem dependência de Flutter.
class CalculatorEngine {
  String _display = '0';
  double? _leftOperand;
  String? _operator;
  bool _replaceDisplay = true;
  bool _awaitingOperand = false;

  String get display => _display.replaceAll('.', ',');

  void press(String key) {
    if (key.length == 1 && '0123456789'.contains(key)) {
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
      case '⌫':
        _backspace();
        return;
      case '±':
        _toggleSign();
        return;
      case '%':
        _percentage();
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
    _awaitingOperand = false;
  }

  void _addDigit(String digit) {
    _awaitingOperand = false;
    if (_replaceDisplay) {
      _display = digit;
      _replaceDisplay = false;
      return;
    }
    if (_display == '-0') {
      _display = '-$digit';
    } else {
      _display = _display == '0' ? digit : '$_display$digit';
    }
  }

  void _addDecimalSeparator() {
    _awaitingOperand = false;
    if (_replaceDisplay) {
      _display = '0.';
      _replaceDisplay = false;
      return;
    }
    if (!_display.contains('.')) {
      _display = '$_display.';
    }
  }

  void _backspace() {
    if (_replaceDisplay) return;
    _display = _display.substring(0, _display.length - 1);
    if (_display.isEmpty || _display == '-') {
      _display = '0';
    }
  }

  void _toggleSign() {
    if (_display == 'Erro') return;
    if (_awaitingOperand) {
      _display = '-0';
      _awaitingOperand = false;
      _replaceDisplay = false;
      return;
    }
    if (_display == '0') {
      _replaceDisplay = false;
    }
    _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
  }

  void _percentage() {
    if (_display == 'Erro' || _awaitingOperand) return;
    final value = _asNumber() / 100;
    // Em somas e subtrações, a porcentagem é relativa ao primeiro valor.
    _display = _format(
      _operator == '+' || _operator == '−' ? _leftOperand! * value : value,
    );
    _replaceDisplay = true;
  }

  void _setOperator(String nextOperator) {
    if (_display == 'Erro') return;
    if (_leftOperand != null && _operator != null && !_awaitingOperand) {
      _calculate();
      if (_display == 'Erro') return;
    }
    _leftOperand ??= _asNumber();
    _operator = nextOperator;
    _replaceDisplay = true;
    _awaitingOperand = true;
  }

  void _calculate() {
    if (_leftOperand == null || _operator == null || _display == 'Erro') return;

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
    _awaitingOperand = false;
  }

  double _asNumber() => double.parse(_display);

  String _format(double value) {
    if (!value.isFinite) return 'Erro';
    // Limita ruídos de ponto flutuante sem zerar números muito pequenos.
    final rounded = double.parse(value.toStringAsPrecision(12));
    if (rounded == 0) return '0';
    if (rounded.abs() >= 1e15 || rounded.abs() < 1e-8) {
      return rounded.toString();
    }
    return rounded == rounded.truncateToDouble()
        ? rounded.truncate().toString()
        : rounded.toString();
  }
}
