// Service for calculating dashboard summary data
import '../models/expense.dart';
import '../models/dashboard_summary.dart';

class SummaryService {
  DashboardSummary calculateSummary(List<Expense> expenses,
      {DateTime? startDate, DateTime? endDate}) {
    double total = 0;
    double avgPerDay = 0;
    MostExpensiveExpense? mostExp;
    MostExpensivePlace? mostExpensivePlace;
    final Map<String, double> placeTotals = {};
    final Map<String, double> descriptionTotals = {};

    if (expenses.isNotEmpty) {
      total = expenses.fold(0, (sum, e) => sum + e.value);
      // Calculate days in the selected filter range
      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        final days = end.difference(start).inDays + 1;
        avgPerDay = days > 0 ? total / days : total;
      } else {
        avgPerDay = total;
      }
      // Group by description for most expensive expense
      for (final e in expenses) {
        final desc = e.description.trim();
        if (desc.isNotEmpty) {
          descriptionTotals[desc] = (descriptionTotals[desc] ?? 0) + e.value;
        }
        final place = e.place;
        if (place.isNotEmpty) {
          placeTotals[place] = (placeTotals[place] ?? 0) + e.value;
        }
      }
      if (descriptionTotals.isNotEmpty) {
        final entry = descriptionTotals.entries
            .reduce((a, b) => a.value >= b.value ? a : b);
        mostExp =
            MostExpensiveExpense(description: entry.key, value: entry.value);
      }
      if (placeTotals.isNotEmpty) {
        final entry =
            placeTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
        final sumValue = placeTotals[entry.key] ?? 0.0;
        mostExpensivePlace =
            MostExpensivePlace(description: entry.key, value: sumValue);
      }
    }

    return DashboardSummary(
      total: total,
      avgPerDay: avgPerDay,
      mostExp: mostExp,
      mostExpensivePlace: mostExpensivePlace,
    );
  }
}
