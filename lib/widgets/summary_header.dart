// Widget for dashboard summary header
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/currency_format_service.dart';
import '../services/user_preferences_service.dart';
import '../utils/responsive_layout.dart';
import '../models/dashboard_summary.dart';

class SummaryHeaderCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const SummaryHeaderCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final labelTextStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.normal);
    final valueTextStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: labelTextStyle, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(value, style: valueTextStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryHeader extends StatelessWidget {
  final DashboardSummary summary;
  final UserPreferences? userPrefs;

  const SummaryHeader({
    super.key,
    required this.summary,
    this.userPrefs,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = userPrefs?.currencySymbol;
    final formatMask = userPrefs?.currencyFormat;
    final totalSpentLabel = 'total_spent'.tr();
    final dailyAvgLabel = 'daily_average'.tr();
    final totalSpentValue = CurrencyFormatService.formatCurrency(
        summary.total, context,
        overrideSymbol: symbol, overrideFormat: formatMask);
    final dailyAvgValue = CurrencyFormatService.formatCurrency(
        summary.avgPerDay, context,
        overrideSymbol: symbol, overrideFormat: formatMask);
    final mostExpValue = summary.mostExp != null
        ? CurrencyFormatService.formatCurrency(summary.mostExp!.value, context,
            overrideSymbol: symbol, overrideFormat: formatMask)
        : '';

    // Use mostCommonPlace from summary
    String? frequentPlaceName;
    String frequentPlaceValue = '';
    if (summary.mostExpensivePlace != null) {
      frequentPlaceName = summary.mostExpensivePlace!.description;
      final placeValue = summary.mostExpensivePlace!.value;
      frequentPlaceValue = CurrencyFormatService.formatCurrency(
        placeValue,
        context,
        overrideSymbol: symbol,
        overrideFormat: formatMask,
      );
    }

    final List<Widget> cards = [
      SummaryHeaderCard(
        icon: Icons.attach_money,
        iconColor: Colors.green,
        label: totalSpentLabel,
        value: totalSpentValue,
      ),
      SummaryHeaderCard(
        icon: Icons.calendar_today,
        iconColor: Colors.blue,
        label: dailyAvgLabel,
        value: dailyAvgValue,
      ),
      if (summary.mostExp != null)
        SummaryHeaderCard(
          icon: Icons.trending_up,
          iconColor: Colors.red,
          label: summary.mostExp!.description,
          value: mostExpValue,
        ),
      if (frequentPlaceName != null && frequentPlaceName.isNotEmpty)
        SummaryHeaderCard(
          icon: Icons.place,
          iconColor: Colors.deepPurple,
          label: frequentPlaceName,
          value: frequentPlaceValue,
        ),
    ];

    final isMobileOrTablet = isMobile(context) || isTablet(context);

    if (isMobileOrTablet) {
      // 2 columns grid for mobile/tablet
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 36) /
                        2, // 2 columns
                    child: card,
                  ))
              .toList(),
        ),
      );
    } else {
      // Row for desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards
            .map((card) => Flexible(
                  fit: FlexFit.tight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: card,
                    ),
                  ),
                ))
            .toList(),
      );
    }
  }
}
