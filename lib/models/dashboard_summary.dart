// Model for dashboard summary data (total, average per month, most expensive expense)
import 'expense.dart';

class DashboardSummary {
  final double total;
  final double avgPerDay;
  final Expense? mostExp;

  DashboardSummary({
    required this.total,
    required this.avgPerDay,
    required this.mostExp,
  });
}
