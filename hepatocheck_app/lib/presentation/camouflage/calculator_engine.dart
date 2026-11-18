/// Motor de expressões com precedência e parênteses.
class CalculatorEngine {
  String _input = '', _display = '0';
  bool _done = false;
  static final _number = RegExp(r'-?\d+(?:\.\d*)?(?:e[+-]?\d+)?$');
  static const _ops = ['+', '−', '×', '÷'];
  String get display => _display.replaceAll('.', ',');
  String get expression => _input
      .replaceAll('.', ',')
      .replaceAllMapped(RegExp('[+−×÷]'), (m) => ' ${m[0]} ');
  void clear() {
    _input = '';
    _display = '0';
    _done = false;
  }

  void press(String key) {
    final digit = key.length == 1 && '0123456789'.contains(key);
    if (key == 'C') {
      clear();
      return;
    }
    if (_display == 'Erro' && !digit && key != ',') return;
    if (digit || key == ',') {
      if (_done || _display == 'Erro') clear();
      if (_input.endsWith(')')) _input += '×';
      final m = _number.firstMatch(_input);
      final n = m?.group(0) ?? '';
      if (key == ',') {
        if (n.contains('.') || n.contains('e')) return;
        _input += n.isEmpty ? '0.' : '.';
      } else if (n == '0' || n == '-0') {
        _input =
            _input.substring(0, m!.start) + (n.startsWith('-') ? '-$key' : key);
      } else {
        _input += key;
      }
      _update();
    } else if (_ops.contains(key)) {
      if (_done) {
        _input = _display;
        _done = false;
      }
      if (_input.isEmpty) _input = '0';
      if (_input.endsWith('(')) return;
      if (_ops.contains(_input[_input.length - 1])) {
        _input = _input.substring(0, _input.length - 1);
      }
      _input += key;
    } else if (key == '()') {
      if (_done) clear();
      final balance =
          '('.allMatches(_input).length - ')'.allMatches(_input).length;
      final complete = _input.endsWith(')') || _number.hasMatch(_input);
      if (balance > 0 && complete) {
        _input += ')';
      } else {
        if (complete) _input += '×';
        _input += '(';
      }
    } else if (key == '⌫') {
      if (_done || _input.isEmpty) return;
      _input = _input.substring(0, _input.length - 1);
      if (_input == '-') _input = '';
      _update();
    } else if (key == '±' || key == '%') {
      if (_done) {
        _input = _display;
        _done = false;
      }
      final m = _number.firstMatch(_input);
      if (m == null) {
        if (key == '±') {
          _input += '-0';
          _display = '-0';
        }
        return;
      }
      var value = double.parse(m.group(0)!);
      if (key == '±') {
        value = -value;
      } else {
        value /= 100;
        final prefix = _input.substring(0, m.start);
        if (prefix.endsWith('+') || prefix.endsWith('−')) {
          // A porcentagem é relativa ao subtotal do grupo atual. Grupos
          // externos ainda abertos não podem ser enviados ao parser.
          var start = 0;
          final openings = <int>[];
          for (var index = 0; index < prefix.length; index++) {
            if (prefix[index] == '(') openings.add(index);
            if (prefix[index] == ')') openings.removeLast();
          }
          if (openings.isNotEmpty) start = openings.last + 1;
          value *= _Parser(prefix.substring(start, prefix.length - 1)).parse();
        }
      }
      _input = _input.substring(0, m.start) + _format(value);
      _update();
    } else if (key == '=') {
      if (_done || _input.isEmpty) return;
      try {
        _input +=
            ')' *
            ('('.allMatches(_input).length - ')'.allMatches(_input).length);
        _display = _format(_Parser(_input).parse());
      } on FormatException {
        _display = 'Erro';
      }
      _done = true;
    }
  }

  void _update() {
    _display = _number.firstMatch(_input)?.group(0) ?? '0';
  }

  String _format(double value) {
    if (!value.isFinite) return 'Erro';
    final n = double.parse(value.toStringAsPrecision(12));
    if (n == 0) return '0';
    if (n.abs() >= 1e15 || n.abs() < 1e-8) return n.toString();
    return n == n.truncateToDouble() ? n.truncate().toString() : n.toString();
  }
}

class _Parser {
  _Parser(this.input);
  final String input;
  int position = 0;
  double parse() {
    final value = _sum();
    if (position != input.length) throw const FormatException();
    return value;
  }

  bool _take(String token) {
    if (!input.startsWith(token, position)) return false;
    position += token.length;
    return true;
  }

  double _sum() {
    var value = _product();
    while (true) {
      if (_take('+')) {
        value += _product();
      } else if (_take('−')) {
        value -= _product();
      } else {
        return value;
      }
    }
  }

  double _product() {
    var value = _factor();
    while (true) {
      if (_take('×')) {
        value *= _factor();
      } else if (_take('÷')) {
        value /= _factor();
      } else {
        return value;
      }
    }
  }

  double _factor() {
    if (_take('-')) return -_factor();
    if (_take('(')) {
      final value = _sum();
      if (!_take(')')) throw const FormatException();
      return value;
    }
    final m = RegExp(r'\d+(?:\.\d*)?(?:e[+-]?\d+)?')
        .matchAsPrefix(input, position);
    if (m == null) throw const FormatException();
    position = m.end;
    return double.parse(m.group(0)!);
  }
}
