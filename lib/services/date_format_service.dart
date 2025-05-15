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

  static String getDateFormat(BuildContext context, {int yearDigits = 4}) {
    final lang = getCurrentLanguage(context);
    String format = _formats[lang] ?? _formats['pt']!;
    if (yearDigits == 2) {
      // Replace 'yyyy' with 'yy' for 2-digit year
      format = format.replaceAll('yyyy', 'yy');
    }
    return format;
  }

  static String formatDate(DateTime date, BuildContext context,
      {int yearDigits = 4}) {
    final format = getDateFormat(context, yearDigits: yearDigits);
    return DateFormat(format).format(date);
  }
}
