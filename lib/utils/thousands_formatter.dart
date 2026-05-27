import 'package:flutter/services.dart';

class ThousandsFormatter extends TextInputFormatter {
  // Como en tus pantallas invocamos "ThousandsFormatter()" sin pasarle parámetros,
  // creamos un constructor vacío para que no tire error en ningún archivo.
  const ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Detectamos si es una moneda sin decimales (como el Guaraní)
    // Podés agregar acá los símbolos que uses que sean enteros absolutos
    final String texto = newValue.text;
    
    // Si la entrada contiene puntos o comas, asumimos que el usuario está metiendo decimales
    // (comportamiento para Dólares, Euros, etc.)
    if (texto.contains('.') || texto.contains(',')) {
      // Permitimos que escriba libremente sus decimales sin forzar puntos fijos
      String clean = texto.replaceAll(RegExp(r'[^0-9.,]'), '');
      return TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }

    // Si son números puros sin signos (estilo Guaraní), formateamos con puntos automáticos
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
  }
}
