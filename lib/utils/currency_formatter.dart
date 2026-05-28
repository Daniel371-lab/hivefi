import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const _noDecimalCurrencies = {'PYG', 'CLP', 'COP', 'CRC'};

  static double parseAmount(String text, String currencyCode) {
    if (text.isEmpty) return 0;
    if (_noDecimalCurrencies.contains(currencyCode)) {
      // Separador de miles es punto, sin decimales
      return double.tryParse(text.replaceAll('.', '')) ?? 0;
    } else {
      // Separador de miles es coma, decimal es punto
      return double.tryParse(text.replaceAll(',', '')) ?? 0;
    }
  }

  static String format(double amount, String currencyCode) {
    switch (currencyCode) {
      case 'PYG':
        return NumberFormat.currency(
          locale: 'es_PY',
          symbol: 'GS ',
          decimalDigits: 0,
        ).format(amount);

      case 'CLP':
        return NumberFormat.currency(
          locale: 'es_CL',
          symbol: '\$',
          decimalDigits: 0,
        ).format(amount);

      case 'COP':
        return NumberFormat.currency(
          locale: 'es_CO',
          symbol: '\$',
          decimalDigits: 0,
        ).format(amount);

      case 'ARS':
        return NumberFormat.currency(
          locale: 'es_AR',
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);

      case 'BRL':
        return NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
          decimalDigits: 2,
        ).format(amount);

      case 'PEN':
        return NumberFormat.currency(
          locale: 'es_PE',
          symbol: 'S/ ',
          decimalDigits: 2,
        ).format(amount);

      case 'UYU':
        return NumberFormat.currency(
          locale: 'es_UY',
          symbol: '\$U ',
          decimalDigits: 2,
        ).format(amount);

      case 'BOB':
        return NumberFormat.currency(
          locale: 'es_BO',
          symbol: 'Bs ',
          decimalDigits: 2,
        ).format(amount);

      case 'VES':
        return NumberFormat.currency(
          locale: 'es_VE',
          symbol: 'Bs.S ',
          decimalDigits: 2,
        ).format(amount);

      case 'MXN':
        return NumberFormat.currency(
          locale: 'es_MX',
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);

      case 'GTQ':
        return NumberFormat.currency(
          locale: 'es_GT',
          symbol: 'Q ',
          decimalDigits: 2,
        ).format(amount);

      case 'HNL':
        return NumberFormat.currency(
          locale: 'es_HN',
          symbol: 'L ',
          decimalDigits: 2,
        ).format(amount);

      case 'NIO':
        return NumberFormat.currency(
          locale: 'es_NI',
          symbol: 'C\$ ',
          decimalDigits: 2,
        ).format(amount);

      case 'CRC':
        return NumberFormat.currency(
          locale: 'es_CR',
          symbol: '₡',
          decimalDigits: 0,
        ).format(amount);

      case 'DOP':
        return NumberFormat.currency(
          locale: 'es_DO',
          symbol: 'RD\$ ',
          decimalDigits: 2,
        ).format(amount);

      case 'USD':
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);

      case 'EUR':
        return NumberFormat.currency(
          locale: 'de_DE',
          symbol: '€',
          decimalDigits: 2,
        ).format(amount);

      default:
        return NumberFormat.currency(
          symbol: currencyCode,
          decimalDigits: 2,
        ).format(amount);
    }
  }
}