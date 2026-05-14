import 'package:flutter/services.dart';

String formatDigitsWithApostrophes(String value) {
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');

  if (digits.isEmpty) return '';

  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    final positionFromEnd = digits.length - i;

    buffer.write(digits[i]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write("'");
    }
  }

  return buffer.toString();
}

String formatPriceWithApostrophes(num price, {bool showDecimals = false}) {
  final integerPart = formatDigitsWithApostrophes(price.round().toString());

  if (!showDecimals) {
    return '\$$integerPart';
  }

  final decimals = price.toStringAsFixed(2).split('.').last;
  return '\$$integerPart.$decimals';
}

double parseFormattedPrice(String value) {
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');

  if (digits.isEmpty) {
    return 0;
  }

  return double.parse(digits);
}

class ApostropheThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = formatDigitsWithApostrophes(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}