import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class CurrencyFormatService {
  static final Map<String, String> _currencySymbols = {
    'pt': 'R\$',
    'en': '\$', // $
    'es': '\$', // $
    // Add more as needed
  };

  static final Map<String, String> _currencyCodes = {
    'pt': 'BRL',
    'en': 'USD',
    'es': 'USD',
    // Add more as needed
  };

  static String getCurrentLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode;
  }

  static String getCurrencySymbol(BuildContext context, {String? override}) {
    if (override != null) return override;
    final lang = getCurrentLanguage(context);
    return _currencySymbols[lang] ?? _currencySymbols['pt']!;
  }

  static String getCurrencyCode(BuildContext context) {
    final lang = getCurrentLanguage(context);
    return _currencyCodes[lang] ?? _currencyCodes['pt']!;
  }

  static String formatCurrency(num value, BuildContext context,
      {String? overrideSymbol, String? overrideFormat}) {
    final symbol = getCurrencySymbol(context, override: overrideSymbol);
    String userFormat = overrideFormat ?? '0.000,00';
    String pattern = _maskToPattern(userFormat);
    final format =
        NumberFormat(pattern, Localizations.localeOf(context).toString());
    return symbol + format.format(value);
  }

  static String _maskToPattern(String mask) {
    // Convert mask like '0.000,00' to NumberFormat pattern '#,##0.00'
    // Accepts both comma and dot as decimal/group separators
    // This is a simple heuristic, not a full mask parser
    if (mask.contains(',') && mask.contains('.')) {
      // e.g. '0.000,00' (pt-BR)
      return '#,##0.00';
    } else if (mask.contains('.') && mask.contains(',')) {
      // e.g. '0,000.00' (en-US)
      return '#,##0.00';
    } else if (mask.contains(',')) {
      // e.g. '0,00' (decimal only)
      return '0.00';
    } else {
      // fallback
      return '#,##0.00';
    }
  }
}
