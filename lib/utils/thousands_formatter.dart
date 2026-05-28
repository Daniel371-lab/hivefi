import 'package:flutter/services.dart';

class ThousandsFormatter extends TextInputFormatter {
  final String currencyCode;

  const ThousandsFormatter({this.currencyCode = 'PYG'});

  static const _noDecimalCurrencies = {'PYG', 'CLP', 'COP', 'CRC'};

  bool get _isNoDecimal => _noDecimalCurrencies.contains(currencyCode);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final String texto = newValue.text;

    if (_isNoDecimal) {
      // Solo dígitos enteros, separador de miles con punto
      String cleanDigits = texto.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.isEmpty) return const TextEditingValue();

      final buffer = StringBuffer();
      for (int i = 0; i < cleanDigits.length; i++) {
        if (i > 0 && (cleanDigits.length - i) % 3 == 0) {
          buffer.write('.');
        }
        buffer.write(cleanDigits[i]);
      }

      return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    } else {
      // Monedas con decimales: permitir dígitos, punto y coma libremente
      // Solo bloqueamos caracteres que no sean numéricos ni separadores
      String clean = texto.replaceAll(RegExp(r'[^0-9.,]'), '');

      // Evitar más de un separador decimal
      final dotCount = clean.split('.').length - 1;
      final commaCount = clean.split(',').length - 1;
      if (dotCount > 1 || commaCount > 1 || (dotCount > 0 && commaCount > 0)) {
        return oldValue;
      }

      return TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
  }
}