import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateFormatService {
  static final Map<String, String> _formats = {
    'pt': 'dd/MM/yyyy',
    'en': 'MM/dd/yyyy',
    'es': 'dd/MM/yyyy',
    // Add more as needed
  };

  static String getCurrentLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode;
  }

  static String getDateFormat(BuildContext context) {
    final lang = getCurrentLanguage(context);
    return _formats[lang] ?? _formats['pt']!;
  }

  static String formatDate(DateTime date, BuildContext context) {
    final format = getDateFormat(context);
    return DateFormat(format).format(date);
  }
}
