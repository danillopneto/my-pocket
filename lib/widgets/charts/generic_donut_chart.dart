import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

class GenericDonutChart<T> extends StatefulWidget {
  final List<T> items;
  final List expenses;
  final String Function(T) getId;
  final String Function(T) getName;
  final String Function(double, BuildContext) formatValue;
  final String Function()? emptyLabelKey;
  final String Function(dynamic expense) getExpenseKey;
  final double Function(dynamic expense) getExpenseValue;
  final double badgePositionPercentageOffset;

  const GenericDonutChart({
    super.key,
    required this.items,
    required this.expenses,
    required this.getId,
    required this.getName,
    required this.formatValue,
    required this.getExpenseKey,
    required this.getExpenseValue,
    this.emptyLabelKey,
    this.badgePositionPercentageOffset = 0.7,
  });

  @override
  State<GenericDonutChart<T>> createState() => _GenericDonutChartState<T>();
}

class _GenericDonutChartState<T> extends State<GenericDonutChart<T>> {
  int? touchedIndex;

  // Default color palette (Excel-like + Material)
  static const List<Color> _defaultColors = [
    Color(0xFF3366CC), // Blue
    Color(0xFFDC3912), // Red
    Color(0xFFFF9900), // Orange
    Color(0xFF109618), // Green
    Color(0xFF990099), // Purple
    Color(0xFF0099C6), // Teal
    Color(0xFFDD4477), // Pink
    Color(0xFF66AA00), // Lime
    Color(0xFFB82E2E), // Dark Red
    Color(0xFF316395), // Dark Blue
    Color(0xFF994499), // Dark Purple
    Color(0xFF22AA99), // Sea Green
    Color(0xFFF44336), // Material Red
    Color(0xFF2196F3), // Material Blue
    Color(0xFF4CAF50), // Material Green
    Color(0xFFFFEB3B), // Material Yellow
    Color(0xFF795548), // Material Brown
    Color(0xFF607D8B), // Material Blue Grey
    Color(0xFFE91E63), // Material Pink
    Color(0xFF673AB7), // Material Deep Purple
  ];

  @override
  Widget build(BuildContext context) {
    // Aggregate expenses by item id
    final Map<String, double> totals = {};
    for (final expense in widget.expenses) {
      final key = widget.getExpenseKey(expense);
      totals[key] = (totals[key] ?? 0) + widget.getExpenseValue(expense);
    }
    final total = totals.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return Center(
          child: Text(widget.emptyLabelKey?.call().tr() ??
              'no_expenses_to_display'.tr()));
    }
    // Sort by value
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<PieChartSectionData> sections = [];
    final legendItems = <Widget>[];
    int colorIndex = 0;
    for (var entry in sortedEntries) {
      final id = entry.key;
      final value = entry.value;
      final item = widget.items.firstWhere(
        (i) => widget.getId(i) == id,
        orElse: () => widget.items.isNotEmpty
            ? widget.items.first
            : (throw Exception('No items')),
      );
      final name = item != null ? widget.getName(item) : 'Unknown';
      final color = _defaultColors[colorIndex % _defaultColors.length];
      final percent = value / total * 100;
      final isSelected = touchedIndex == colorIndex;
      // Legend
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
                  name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${widget.formatValue(value, context)} (${percent.toStringAsFixed(1)}%)',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
      // Pie section
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '',
          radius: isSelected ? 65 : 55,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          badgeWidget: isSelected
              ? _BadgeWithLabel(name, value, context,
                  formatValue: widget.formatValue)
              : null,
          badgePositionPercentageOffset: widget.badgePositionPercentageOffset,
        ),
      );
      colorIndex++;
    }
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(
                top: 24.0, bottom: 12.0), // Add bottom padding
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
                          centerSpaceRadius: 45,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Add extra space between chart and legend
        const SizedBox(height: 12),
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
    );
  }
}

class _BadgeWithLabel extends StatelessWidget {
  final String label;
  final double value;
  final BuildContext context;
  final String Function(double, BuildContext)? formatValue;

  const _BadgeWithLabel(this.label, this.value, this.context,
      {this.formatValue});

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
            formatValue != null
                ? formatValue!(value, context)
                : value.toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
