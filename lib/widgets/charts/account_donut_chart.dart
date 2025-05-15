// Donut chart for expenses by account with improved Excel-like styling
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';

class AccountDonutChart extends StatefulWidget {
  final List<Account> accounts;
  final List<Expense> expenses;

  const AccountDonutChart({
    super.key,
    required this.accounts,
    required this.expenses,
  });

  @override
  State<AccountDonutChart> createState() => _AccountDonutChartState();
}

class _AccountDonutChartState extends State<AccountDonutChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    // Aggregate expenses by account
    final Map<String, double> accountTotals = {};
    for (final expense in widget.expenses) {
      accountTotals[expense.accountId] =
          (accountTotals[expense.accountId] ?? 0) + expense.value;
    }

    final total = accountTotals.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return Center(child: Text('no_expenses_to_display'.tr()));
    }

    // Sort by value to make chart more readable
    final sortedEntries = accountTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartSectionData> sections = [];

    // Excel-like vibrant colors
    final colors = [
      const Color(0xFF3366CC), // Blue
      const Color(0xFFDC3912), // Red
      const Color(0xFFFF9900), // Orange
      const Color(0xFF109618), // Green
      const Color(0xFF990099), // Purple
      const Color(0xFF0099C6), // Teal
      const Color(0xFFDD4477), // Pink
      const Color(0xFF66AA00), // Lime
      const Color(0xFFB82E2E), // Dark Red
      const Color(0xFF316395), // Dark Blue
      const Color(0xFF994499), // Dark Purple
      const Color(0xFF22AA99), // Sea Green
    ];

    // Build legend items separately
    final legendItems = <Widget>[];
    int colorIndex = 0;

    // Process each account for the chart
    for (var entry in sortedEntries) {
      final accountId = entry.key;
      final value = entry.value;

      final account = widget.accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => Account(id: accountId, name: 'Unknown'),
      );

      final color = colors[colorIndex % colors.length];
      final percent = value / total * 100;
      final isSelected = touchedIndex == colorIndex;

      // Add to legend
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                // Format: {Currency Symbol}: {value} ({percentage}%) using CurrencyFormatService
                '${CurrencyFormatService.formatCurrency(value, context)} (${percent.toStringAsFixed(1)}%)',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

      // Create pie chart section
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '', // Remove slice text
          radius:
              isSelected ? 65 : 55, // Slightly reduced radius to prevent cutoff
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          badgeWidget:
              isSelected ? _BadgeWithLabel(account.name, value, context) : null,
          badgePositionPercentageOffset: 1.1, // Adjusted to prevent cutoff
        ),
      );
      colorIndex++;
    }
    return ClipRect(
      // Added ClipRect for safety, though Expanded should prevent overflow
      child: Column(
        children: [
          // Chart
          Expanded(
            // Ensures chart takes up its allocated space
            flex: 2, // Give chart more space than legend
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 40.0), // Increased top padding to prevent cutoff
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 45, // Adjusted center space
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                          ),
                        ),
                        // Center text
                        // Removed total from center
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Legend always below
          Expanded(
            // Ensures legend takes up remaining space and can scroll
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legendItems,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Badge for displaying values
class _Badge extends StatelessWidget {
  final double value;

  const _Badge(this.value);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: 56,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          CurrencyFormatService.formatCurrency(value, context),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Add this new badge widget below the existing _Badge class
class _BadgeWithLabel extends StatelessWidget {
  final String label;
  final double value;
  final BuildContext context;

  const _BadgeWithLabel(this.label, this.value, this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: 80,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            CurrencyFormatService.formatCurrency(value, context),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
