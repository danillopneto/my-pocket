class MostExpensiveExpense {
  final String description;
  final double value;
  MostExpensiveExpense({required this.description, required this.value});
}

class MostExpensivePlace {
  final String description;
  final double value;
  MostExpensivePlace({required this.description, required this.value});
}

class DashboardSummary {
  final double total;
  final double avgPerDay;
  final MostExpensiveExpense? mostExp;
  final MostExpensivePlace? mostExpensivePlace;

  DashboardSummary({
    required this.total,
    required this.avgPerDay,
    required this.mostExp,
    required this.mostExpensivePlace,
  });
}
