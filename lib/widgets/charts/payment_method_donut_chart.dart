import 'package:flutter/material.dart';
import '../../models/payment-method.dart';
import '../../models/expense.dart';
import '../../services/currency_format_service.dart';
import 'generic_donut_chart.dart';

class PaymentMethodDonutChart extends StatelessWidget {
  final List<PaymentMethod> paymentMethods;
  final List<Expense> expenses;

  const PaymentMethodDonutChart({
    super.key,
    required this.paymentMethods,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDonutChart<PaymentMethod>(
      items: paymentMethods,
      expenses: expenses,
      getId: (a) => a.id ?? '',
      getName: (a) => a.name,
      formatValue: (v, ctx) => CurrencyFormatService.formatCurrency(v, ctx),
      getExpenseKey: (e) => e.paymentMethodId ?? '',
      getExpenseValue: (e) => e.value,
      emptyLabelKey: () => 'no_expenses_to_display',
      badgePositionPercentageOffset: 1.1,
    );
  }
}
