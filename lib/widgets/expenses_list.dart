import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment-method.dart';
import 'package:easy_localization/easy_localization.dart';
import 'expense_card.dart';

class ExpensesList extends StatelessWidget {
  final List<Expense> expenses;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final void Function(Expense)? onEdit;
  final void Function(Expense)? onDelete;
  final bool showTotal;
  final bool isCompact;
  final double? totalOverride;
  final String? currencySymbolOverride;
  final String? currencyFormatOverride;

  const ExpensesList({
    super.key,
    required this.expenses,
    required this.categories,
    required this.paymentMethods,
    this.onEdit,
    this.onDelete,
    this.showTotal = true,
    this.isCompact = false,
    this.totalOverride,
    this.currencySymbolOverride,
    this.currencyFormatOverride,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        totalOverride ?? expenses.fold<double>(0, (sum, e) => sum + e.value);
    final grouped = _groupedExpensesByDay(expenses);
    return Column(
      children: [
        Expanded(
          child: grouped.isEmpty
              ? Center(child: Text('no_expenses_found'.tr()))
              : ListView.builder(
                  itemCount: grouped.length,
                  itemBuilder: (context, groupIdx) {
                    final group = grouped[groupIdx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            // Use yMMMMd for consistency
                            MaterialLocalizations.of(context)
                                .formatFullDate(group['date']),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ...group['expenses'].map<Widget>((e) {
                          final category = categories.firstWhere(
                            (c) => c.id == e.categoryId,
                            orElse: () => Category(id: '', name: 'Unknown'),
                          );
                          final paymentMethod = paymentMethods.firstWhere(
                            (a) => a.id == e.paymentMethodId,
                            orElse: () =>
                                PaymentMethod(id: '', name: 'Unknown'),
                          );
                          return ExpenseCard(
                            expense: e,
                            category: category,
                            paymentMethod: paymentMethod,
                            onEdit: onEdit != null ? () => onEdit!(e) : () {},
                            onDelete:
                                onDelete != null ? () => onDelete!(e) : () {},
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
        ),
        if (showTotal)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${'total'.tr()}: ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _groupedExpensesByDay(List<Expense> expenses) {
    final List<Map<String, dynamic>> groups = [];
    if (expenses.isEmpty) return groups;
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    DateTime? currentDate;
    List<Expense> currentGroup = [];
    for (final exp in sorted) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      if (currentDate == null || expDate != currentDate) {
        if (currentGroup.isNotEmpty) {
          groups.add({'date': currentDate!, 'expenses': currentGroup});
        }
        currentDate = expDate;
        currentGroup = [exp];
      } else {
        currentGroup.add(exp);
      }
    }
    if (currentGroup.isNotEmpty) {
      groups.add({'date': currentDate!, 'expenses': currentGroup});
    }
    return groups;
  }
}
