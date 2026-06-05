import 'package:flutter/services.dart';

class ThousandsFormatter extends TextInputFormatter {
  final String currencyCode;

  const ThousandsFormatter({this.currencyCode = 'PYG'});

  static const _noDecimalCurrencies = {'PYG', 'CLP', 'COP', 'CRC'};

  bool get _isNoDecimal => _noDecimalCurrencies.contains(currencyCode);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    if (_isNoDecimal) {
      // Solo enteros con separador de miles (punto)
      final digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return const TextEditingValue();

      final buffer = StringBuffer();
      for (int i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(digits[i]);
      }

      final result = buffer.toString();
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    } else {
      String clean = text.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');

      // Evitar múltiples puntos
      final parts = clean.split('.');
      if (parts.length > 2) {
        clean = '${parts[0]}.${parts[1]}';
      }

      // Limitar a 2 decimales
      if (parts.length == 2 && parts[1].length > 2) {
        clean = '${parts[0]}.${parts[1].substring(0, 2)}';
      }

      // Formatear parte entera con comas
      final intPart = clean.split('.')[0];
      final decPart = clean.contains('.') ? '.${clean.split('.')[1]}' : '';

      final buffer = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(intPart[i]);
      }

      final result = '${buffer.toString()}$decPart';
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }
  }
}