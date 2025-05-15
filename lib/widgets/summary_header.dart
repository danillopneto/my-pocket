// Widget for dashboard summary header
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/currency_format_service.dart';
import '../services/user_preferences_service.dart';

class SummaryHeader extends StatelessWidget {
  final double total;
  final double avgPerMonth;
  final dynamic mostExp; // Expense or null
  final List categories;
  final List accounts;
  final UserPreferences? userPrefs;

  const SummaryHeader({
    super.key,
    required this.total,
    required this.avgPerMonth,
    required this.mostExp,
    required this.categories,
    required this.accounts,
    this.userPrefs,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = userPrefs?.currencySymbol;
    final formatMask = userPrefs?.currencyFormat;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('total_spent'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            Text(
                CurrencyFormatService.formatCurrency(total, context,
                    overrideSymbol: symbol, overrideFormat: formatMask),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text('average_per_month'.tr() +
                CurrencyFormatService.formatCurrency(avgPerMonth, context,
                    overrideSymbol: symbol, overrideFormat: formatMask)),
            const SizedBox(height: 12),
            if (mostExp != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('most_expensive'.tr()),
                  Text(
                    mostExp.description +
                        ' - ' +
                        CurrencyFormatService.formatCurrency(
                            mostExp.value, context,
                            overrideSymbol: symbol, overrideFormat: formatMask),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
