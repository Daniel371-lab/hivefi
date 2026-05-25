import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, String currencyCode) {
    switch (currencyCode) {
      case 'PYG':
        final formatter = NumberFormat.currency(
          locale: 'es_PY',
          symbol: 'GS ',
          decimalDigits: 0,
        );
        return formatter.format(amount);

      case 'USD':
        final formatter = NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 2,
        );
        return formatter.format(amount);

      case 'EUR':
        final formatter = NumberFormat.currency(
          locale: 'de_DE',
          symbol: '€',
          decimalDigits: 2,
        );
        return formatter.format(amount);

      default:
        return NumberFormat.currency(
          symbol: currencyCode,
          decimalDigits: 2,
        ).format(amount);
    }
  }
}