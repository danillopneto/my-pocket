// Donut chart for expenses by category with improved Excel-like styling
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';

class CategoryDonutChart extends StatefulWidget {
  final List<Category> categories;
  final List<Expense> expenses;

  const CategoryDonutChart({
    super.key,
    required this.categories,
    required this.expenses,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    // Aggregate expenses by category
    final Map<String, double> categoryTotals = {};
    for (final expense in widget.expenses) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.value;
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return Center(child: Text('no_expenses_to_display'.tr()));
    }

    // Sort by value to make chart more readable
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartSectionData> sections = [];

    // Excel-like vibrant colors
    final colors = [
      const Color(0xFFF44336), // Red
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF009688), // Teal
      const Color(0xFFE91E63), // Pink
      const Color(0xFF673AB7), // Deep Purple
    ];

    // Build legend items separately
    final legendItems = <Widget>[];
    int colorIndex = 0;

    // Process each category for the chart
    for (var entry in sortedEntries) {
      final categoryId = entry.key;
      final value = entry.value;

      final category = widget.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(id: categoryId, name: 'Unknown'),
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
                  category.name,
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
          radius: isSelected ? 65 : 55,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          badgeWidget: isSelected
              ? _BadgeWithLabel(category.name, value, context)
              : null,
          badgePositionPercentageOffset: 0.7, // Move badge closer to center
        ),
      );
      colorIndex++;
    }

    return ClipRect(
      child: Column(
        children: [
          // Chart
          Expanded(
            flex: 2,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 40.0), // Increased top padding
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
