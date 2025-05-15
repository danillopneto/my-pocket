import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';
import 'generic_donut_chart.dart';

class AccountDonutChart extends StatelessWidget {
  final List<Account> accounts;
  final List<Expense> expenses;

  const AccountDonutChart({
    super.key,
    required this.accounts,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDonutChart<Account>(
      items: accounts,
      expenses: expenses,
      getId: (a) => a.id ?? '',
      getName: (a) => a.name,
      formatValue: (v, ctx) => CurrencyFormatService.formatCurrency(v, ctx),
      getExpenseKey: (e) => e.accountId ?? '',
      getExpenseValue: (e) => e.value,
      emptyLabelKey: () => 'no_expenses_to_display',
      badgePositionPercentageOffset: 1.1,
    );
  }
}
