// Bar chart for expenses by date with improved Excel-like styling
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';
import '../../services/date_format_service.dart';

class DateBarChart extends StatefulWidget {
  final List<Expense> expenses;

  const DateBarChart({
    super.key,
    required this.expenses,
  });

  @override
  State<DateBarChart> createState() => _DateBarChartState();
}

class _DateBarChartState extends State<DateBarChart> {
  int touchedIndex = -1;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) {
      return Center(child: Text('no_expenses_to_display'.tr()));
    }

    // Group expenses by date (e.g., by day)
    final Map<DateTime, double> dateTotals = {};
    for (final expense in widget.expenses) {
      final date =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      dateTotals[date] = (dateTotals[date] ?? 0) + expense.value;
    }

    // Sort dates in descending order (most recent first)
    final sortedDates = dateTotals.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final maxY = dateTotals.values.isNotEmpty
        ? dateTotals.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Calculate average value
    final avgValue = dateTotals.values.isNotEmpty
        ? dateTotals.values.reduce((a, b) => a + b) / dateTotals.values.length
        : 0.0;

    return ClipRect(
      child: Column(
        children: [
          // Chart
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 16,
                  right: 8,
                  left: 8,
                  bottom:
                      24), // Increased bottom padding for space after labels
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minBarWidth = 40.0;
                  const barSpacing = 16.0;
                  final barCount = sortedDates.length;
                  final neededWidth = barCount > 0
                      ? (barCount * minBarWidth) + ((barCount - 1) * barSpacing)
                      : constraints.maxWidth;
                  return neededWidth > constraints.maxWidth
                      ? Scrollbar(
                          thumbVisibility: true,
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 16.0,
                                  bottom: 24.0), // Add bottom padding here
                              child: SizedBox(
                                width: neededWidth,
                                child: BarChart(
                                  BarChartData(
                                    alignment:
                                        barCount * (minBarWidth + barSpacing) <
                                                constraints.maxWidth
                                            ? BarChartAlignment.spaceEvenly
                                            : BarChartAlignment.spaceBetween,
                                    maxY: maxY == 0 ? 10 : maxY * 1.35,
                                    minY: 0,
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: Colors.grey.shade800,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          final date = sortedDates[groupIndex];
                                          return BarTooltipItem(
                                            CurrencyFormatService
                                                .formatCurrency(
                                                    dateTotals[date]!, context),
                                            const TextStyle(
                                              color: Colors.yellow,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                      touchCallback: (FlTouchEvent event,
                                          barTouchResponse) {
                                        setState(() {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              barTouchResponse == null ||
                                              barTouchResponse.spot == null) {
                                            touchedIndex = -1;
                                            return;
                                          }
                                          touchedIndex = barTouchResponse
                                              .spot!.touchedBarGroupIndex;
                                        });
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget:
                                                (double value, TitleMeta meta) {
                                              final idx = value.toInt();
                                              if (idx < 0 ||
                                                  idx >= sortedDates.length) {
                                                return const SizedBox.shrink();
                                              }
                                              final date = sortedDates[idx];
                                              String label =
                                                  DateFormatService.formatDate(
                                                      date, context,
                                                      yearDigits: 2);
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize:
                                              52, // Increased from 40 to 52
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                value.toInt().toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      checkToShowHorizontalLine: (value) {
                                        // Prevent division by zero and handle small values better
                                        if (maxY <= 0) return value == 0;
                                        double interval =
                                            maxY > 5 ? (maxY / 5) : 1;
                                        return value % interval < 0.01 ||
                                            (value % interval) >
                                                interval - 0.01;
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
                                        bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1),
                                        left: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1),
                                      ),
                                    ),
                                    // Average value line
                                    extraLinesData: ExtraLinesData(
                                      horizontalLines: [
                                        HorizontalLine(
                                          y: avgValue,
                                          color: const Color(0xFFFF5722),
                                          strokeWidth: 2,
                                          dashArray: [8, 4],
                                          label: HorizontalLineLabel(
                                            show: true,
                                            alignment: Alignment
                                                .topLeft, // Move label to the beginning (left)
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            style: const TextStyle(
                                              color: Color(0xFFFF5722),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                            labelResolver: (line) =>
                                                '${'avg'.tr()}: ${CurrencyFormatService.formatCurrency(avgValue, context)}',
                                          ),
                                        ),
                                      ],
                                    ),
                                    barGroups: [
                                      for (int i = 0;
                                          i < sortedDates.length;
                                          i++)
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: dateTotals[sortedDates[i]]!,
                                              color: i == touchedIndex
                                                  ? Colors.amber
                                                  : const Color(0xFF2196F3),
                                              width: 16,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(4),
                                                topRight: Radius.circular(4),
                                              ),
                                              backDrawRodData:
                                                  BackgroundBarChartRodData(
                                                show: true,
                                                toY: maxY * 1.1,
                                                color: const Color(0xFFEEEEEE),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: BarChart(
                              BarChartData(
                                alignment:
                                    barCount * (minBarWidth + barSpacing) <
                                            constraints.maxWidth
                                        ? BarChartAlignment.spaceEvenly
                                        : BarChartAlignment.spaceBetween,
                                maxY: maxY == 0 ? 10 : maxY * 1.35,
                                minY: 0,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.grey.shade800,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final date = sortedDates[groupIndex];
                                      return BarTooltipItem(
                                        CurrencyFormatService.formatCurrency(
                                            dateTotals[date]!, context),
                                        const TextStyle(
                                          color: Colors.yellow,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  touchCallback:
                                      (FlTouchEvent event, barTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          barTouchResponse == null ||
                                          barTouchResponse.spot == null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = barTouchResponse
                                          .spot!.touchedBarGroupIndex;
                                    });
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget:
                                            (double value, TitleMeta meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 ||
                                              idx >= sortedDates.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = sortedDates[idx];
                                          String label =
                                              DateFormatService.formatDate(
                                                  date, context,
                                                  yearDigits: 2);
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        }),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize:
                                          52, // Increased from 40 to 52
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
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
                                    bottom: BorderSide(
                                        color: Colors.grey.shade300, width: 1),
                                    left: BorderSide(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                ),
                                // Average value line
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: avgValue,
                                      color: const Color(0xFFFF5722),
                                      strokeWidth: 2,
                                      dashArray: [8, 4],
                                      label: HorizontalLineLabel(
                                        show: true,
                                        alignment: Alignment
                                            .topLeft, // Move label to the beginning (left)
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 4),
                                        style: const TextStyle(
                                          color: Color(0xFFFF5722),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                        labelResolver: (line) =>
                                            '${'avg'.tr()}: ${CurrencyFormatService.formatCurrency(avgValue, context)}',
                                      ),
                                    ),
                                  ],
                                ),
                                barGroups: [
                                  for (int i = 0; i < sortedDates.length; i++)
                                    BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: dateTotals[sortedDates[i]]!,
                                          color: i == touchedIndex
                                              ? Colors.amber
                                              : const Color(0xFF2196F3),
                                          width: 16,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            topRight: Radius.circular(4),
                                          ),
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                            show: true,
                                            toY: maxY * 1.1,
                                            color: const Color(0xFFEEEEEE),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                },
              ),
            ),
          ),
          // Legend always below
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'daily_expenses'.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 2,
                  color: const Color(0xFFFF5722),
                ),
                const SizedBox(width: 4),
                Text(
                  'daily_average'.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
