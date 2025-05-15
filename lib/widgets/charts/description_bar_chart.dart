// Bar chart for expenses by description with improved Excel-like styling
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';

class DescriptionBarChart extends StatefulWidget {
  final List<Expense> expenses;

  const DescriptionBarChart({
    super.key,
    required this.expenses,
  });

  @override
  State<DescriptionBarChart> createState() => _DescriptionBarChartState();
}

class _DescriptionBarChartState extends State<DescriptionBarChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) {
      return Center(child: Text('no_expenses_to_display'.tr()));
    }

    // Group expenses by description
    final Map<String, double> descTotals = {};
    for (final expense in widget.expenses) {
      descTotals[expense.description] =
          (descTotals[expense.description] ?? 0) + expense.value;
    }

    // Show only top 10 descriptions by total value
    final sortedEntries = descTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(10).toList();

    final maxY = topEntries.isNotEmpty
        ? topEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Excel-like vibrant colors for bars
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

    return ClipRect(
      child: Column(
        children: [
          // Chart
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16, left: 8),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY == 0 ? 10 : maxY * 1.2,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = topEntries[groupIndex];
                        return BarTooltipItem(
                          '${entry.key}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: CurrencyFormatService.formatCurrency(
                                  entry.value, context),
                              style: TextStyle(
                                color: Colors.yellow.shade400,
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
                        touchedIndex =
                            barTouchResponse.spot!.touchedBarGroupIndex;
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
                          if (idx < 0 || idx >= topEntries.length) {
                            return const SizedBox.shrink();
                          }
                          final desc = topEntries[idx].key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Text(
                                desc.length > 12
                                    ? '${desc.substring(0, 12)}…'
                                    : desc,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: idx == touchedIndex
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: idx == touchedIndex
                                      ? Colors.black
                                      : Colors.black54,
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    checkToShowHorizontalLine: (value) {
                      // Prevent division by zero and handle small values better
                      if (maxY <= 0) return value == 0;
                      double interval = maxY > 5 ? (maxY / 5) : 1;
                      return value % interval < 0.01 ||
                          (value % interval) > interval - 0.01;
                    },
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xffe7e8ec),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < topEntries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: topEntries[i].value,
                            color: i == touchedIndex
                                ? Colors.amber
                                : barColors[i % barColors.length],
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY * 1.1,
                              color: const Color(0xFFEEEEEE),
                            ),
                          ),
                        ],
                        showingTooltipIndicators: i == touchedIndex ? [0] : [],
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Legend always below
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0;
                      i < (topEntries.length > 5 ? 5 : topEntries.length);
                      i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: barColors[i % barColors.length],
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            topEntries[i].key.length > 6
                                ? '${topEntries[i].key.substring(0, 6)}...'
                                : topEntries[i].key,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyFormatService.formatCurrency(
                                topEntries[i].value, context),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
