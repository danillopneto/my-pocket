import 'package:flutter/material.dart';
import 'generic_donut_chart.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';

class CategoryDonutChart extends StatelessWidget {
  final List<Category> categories;
  final List<Expense> expenses;

  const CategoryDonutChart({
    super.key,
    required this.categories,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDonutChart<Category>(
      items: categories,
      expenses: expenses,
      getId: (c) => c.id ?? '',
      getName: (c) => c.name,
      formatValue: (v, ctx) => CurrencyFormatService.formatCurrency(v, ctx),
      getExpenseKey: (e) => e.categoryId ?? '',
      getExpenseValue: (e) => e.value,
      emptyLabelKey: () => 'no_expenses_to_display',
      badgePositionPercentageOffset: 0.7,
    );
  }
}
