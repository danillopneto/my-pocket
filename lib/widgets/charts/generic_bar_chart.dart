import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// GenericBarChart for showing top 10 expenses grouped by a key (e.g., description, place)
class GenericBarChart<T> extends StatefulWidget {
  final List<T> items;
  final List expenses;
  final String Function(T) getId;
  final String Function(T) getName;
  final String Function(double, BuildContext) formatValue;
  final String Function(dynamic expense) getExpenseKey;
  final double Function(dynamic expense) getExpenseValue;

  const GenericBarChart(
      {super.key,
      required this.items,
      required this.expenses,
      required this.getId,
      required this.getName,
      required this.formatValue,
      required this.getExpenseKey,
      required this.getExpenseValue});

  @override
  State<GenericBarChart<T>> createState() => _GenericBarChartState<T>();
}

class _GenericBarChartState<T> extends State<GenericBarChart<T>> {
  int touchedIndex = -1;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group expenses by key
    final Map<String, double> groupTotals = {};
    for (final expense in widget.expenses) {
      final key = widget.getExpenseKey(expense);
      groupTotals[key] =
          (groupTotals[key] ?? 0) + widget.getExpenseValue(expense);
    }

    // Map key to display name
    final Map<String, String> keyToName = {
      for (final item in widget.items) widget.getId(item): widget.getName(item)
    };

    // Sort and take top 10
    final sortedEntries = groupTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final allEntries = sortedEntries.take(10).toList();
    final maxY = allEntries.isNotEmpty
        ? allEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Vibrant colors that work well in both light and dark modes
    final barColors = [
      const Color(0xFFF44336), // Red
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];

    // Calculate legend rows for dynamic height
    const legendItemWidth = 120.0;
    final chartWidth =
        MediaQuery.of(context).size.width - 32; // 16px padding each side
    final itemsPerRow = chartWidth ~/ legendItemWidth;
    (allEntries.length / (itemsPerRow > 0 ? itemsPerRow : 1)).ceil();
    // Chart height: base + legend rows * per-row height

    return ClipRect(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 16, right: 40, left: 8, bottom: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minBarWidth = 40.0;
                  const barSpacing = 16.0;
                  final barCount = allEntries.length;
                  final neededWidth = barCount > 0
                      ? (barCount * minBarWidth) + ((barCount - 1) * barSpacing)
                      : constraints.maxWidth;
                  if (neededWidth > constraints.maxWidth) {
                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 40.0, bottom: 24.0),
                          child: SizedBox(
                            width: neededWidth,
                            child: _buildBarChart(context, allEntries, maxY,
                                barColors, keyToName),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(right: 40.0),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: _buildBarChart(
                            context, allEntries, maxY, barColors, keyToName),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          // Legend always below
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate how many legend items fit per row
                const legendItemWidth = 120.0; // Estimate per legend item
                final itemsPerRow = constraints.maxWidth ~/ legendItemWidth;
                final rows = <List<Widget>>[];
                for (int i = 0; i < allEntries.length; i += itemsPerRow) {
                  rows.add([
                    for (int j = i;
                        j < i + itemsPerRow && j < allEntries.length;
                        j++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: barColors[j % barColors.length],
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              keyToName[allEntries[j].key] ?? allEntries[j].key,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.formatValue(allEntries[j].value, context),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ]);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in rows)
                      Wrap(
                        spacing: 0,
                        runSpacing: 0,
                        children: row,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      BuildContext context,
      List<MapEntry<String, double>> allEntries,
      double maxY,
      List<Color> barColors,
      Map<String, String> keyToName) {
    return BarChart(
      BarChartData(
        alignment: allEntries.length * (40.0 + 16.0) < 300
            ? BarChartAlignment.spaceEvenly
            : BarChartAlignment.spaceBetween,
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = allEntries[groupIndex];
              return BarTooltipItem(
                '${keyToName[entry.key] ?? entry.key}\n',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: widget.formatValue(entry.value, context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= allEntries.length) {
                  return const SizedBox.shrink();
                }
                final name =
                    keyToName[allEntries[idx].key] ?? allEntries[idx].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Text(
                      name.length > 12 ? '${name.substring(0, 12)}…' : name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: idx == touchedIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: idx == touchedIndex
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) {
            if (maxY <= 0) return value == 0;
            double interval = maxY > 5 ? (maxY / 5) : 1;
            return value % interval < 0.01 ||
                (value % interval) > interval - 0.01;
          },
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline, width: 1),
            left: BorderSide(
                color: Theme.of(context).colorScheme.outline, width: 1),
          ),
        ),
        barGroups: [
          for (int i = 0; i < allEntries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: allEntries[i].value,
                  color: i == touchedIndex
                      ? const Color(0xFFFFD700) // Gold highlight
                      : barColors[i % barColors.length],
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.1,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                ),
              ],
              showingTooltipIndicators: i == touchedIndex ? [0] : [],
            ),
        ],
      ),
    );
  }
}
