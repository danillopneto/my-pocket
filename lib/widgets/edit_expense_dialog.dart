import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../widgets/expense_form.dart';
import 'package:easy_localization/easy_localization.dart';

class EditExpenseDialog extends StatelessWidget {
  final Expense expense;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final Future<void> Function(Expense edited) onSubmit;
  final bool isNew;

  const EditExpenseDialog({
    super.key,
    required this.expense,
    required this.categories,
    required this.paymentMethods,
    required this.onSubmit,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text((isNew ? 'add_expense' : 'edit_expense').tr()),
      content: ExpenseForm(
        onSubmit: (edited) async {
          await onSubmit(edited);
          if (context.mounted) Navigator.of(context).pop();
        },
        initial: expense,
        categories: categories,
        paymentMethods: paymentMethods,
      ),
    );
  }
}
