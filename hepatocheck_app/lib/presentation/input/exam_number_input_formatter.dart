import 'package:flutter/services.dart';

class ExamNumberInputFormatter extends TextInputFormatter {
  const ExamNumberInputFormatter({
    required this.maxIntegerDigits,
    this.decimal = true,
    this.maxDecimalDigits = 2,
  });

  static const separator = ',';

  final int maxIntegerDigits;
  final bool decimal;
  final int maxDecimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final kept = <(String, int)>[];
    var hasSeparator = false;
    var decimalDigits = 0;

    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (_isDigit(char)) {
        if (hasSeparator) {
          if (decimalDigits >= maxDecimalDigits) continue;
          decimalDigits++;
        }
        kept.add((char, index));
      } else if (decimal && (char == ',' || char == '.') && !hasSeparator) {
        hasSeparator = true;
        kept.add((separator, index));
      }
    }

    if (kept.isNotEmpty && kept.first.$1 == separator) {
      kept.insert(0, ('0', kept.first.$2));
    }
    while (kept.length > 1 && kept[0].$1 == '0' && _isDigit(kept[1].$1)) {
      kept.removeAt(0);
    }

    final integerDigits = kept.takeWhile((item) => item.$1 != separator).length;
    if (integerDigits > maxIntegerDigits) return oldValue;

    final formatted = kept.map((item) => item.$1).join();
    int mapOffset(int offset) => kept.where((item) => item.$2 < offset).length;

    return TextEditingValue(
      text: formatted,
      selection: newValue.selection.isValid
          ? TextSelection(
              baseOffset: mapOffset(newValue.selection.baseOffset),
              extentOffset: mapOffset(newValue.selection.extentOffset),
            )
          : TextSelection.collapsed(offset: formatted.length),
    );
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}
