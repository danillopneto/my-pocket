import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import 'package:easy_localization/easy_localization.dart';
import 'expense_card.dart';
import '../services/date_format_service.dart';

class ExpensesList extends StatefulWidget {
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
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.totalOverride ??
        widget.expenses.fold<double>(0, (sum, e) => sum + e.value);
    final allExpenses = List<Expense>.from(widget.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final totalPages = (allExpenses.length / _itemsPerPage).ceil();
    final startIdx = _currentPage * _itemsPerPage;
    final endIdx = (_currentPage + 1) * _itemsPerPage;
    final pageExpenses = allExpenses.sublist(
      startIdx,
      endIdx > allExpenses.length ? allExpenses.length : endIdx,
    );
    final grouped = _groupedExpensesByDay(pageExpenses);

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
                            DateFormatService.formatDate(
                                group['date'], context),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        ...group['expenses'].map<Widget>((e) {
                          final category = widget.categories.firstWhere(
                            (c) => c.id == e.categoryId,
                            orElse: () => Category(id: '', name: 'Unknown'),
                          );
                          final paymentMethod =
                              widget.paymentMethods.firstWhere(
                            (a) => a.id == e.paymentMethodId,
                            orElse: () =>
                                PaymentMethod(id: '', name: 'Unknown'),
                          );
                          return ExpenseCard(
                            expense: e,
                            category: category,
                            paymentMethod: paymentMethod,
                            onEdit: widget.onEdit != null
                                ? () => widget.onEdit!(e)
                                : () {},
                            onDelete: widget.onDelete != null
                                ? () => widget.onDelete!(e)
                                : () {},
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              child: Text('previous'.tr()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                // Localize 'Page' and use string interpolation for page info
                '${'page'.tr()} ${_currentPage + 1} / $totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              child: Text('next'.tr()),
            ),
          ],
        ),
        if (widget.showTotal)
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
        if (currentGroup.isNotEmpty && currentDate != null) {
          groups.add({'date': currentDate, 'expenses': currentGroup});
        }
        currentDate = expDate;
        currentGroup = [exp];
      } else {
        currentGroup.add(exp);
      }
    }
    if (currentGroup.isNotEmpty && currentDate != null) {
      groups.add({'date': currentDate, 'expenses': currentGroup});
    }
    return groups;
  }
}
