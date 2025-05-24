// Model for dashboard summary data (total, average per month, most expensive expense)
import 'expense.dart';

class DashboardSummary {
  final double total;
  final double avgPerMonth;
  final Expense? mostExp;

  DashboardSummary({
    required this.total,
    required this.avgPerMonth,
    required this.mostExp,
  });
}
