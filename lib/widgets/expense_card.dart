import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment-method.dart';
import '../services/currency_format_service.dart';
import '../services/date_format_service.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Category category;
  final PaymentMethod paymentMethod;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.category,
    required this.paymentMethod,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.description,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Text(
              CurrencyFormatService.formatCurrency(
                expense.value,
                context,
              ),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(DateFormatService.formatDate(expense.date, context),
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Icon(Icons.place, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(expense.place, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(category.name, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Icon(Icons.account_balance_wallet,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(paymentMethod.name,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('x${expense.installments}',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        trailing: Wrap(
          direction: Axis.vertical,
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
