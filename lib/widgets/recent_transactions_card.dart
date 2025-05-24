import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/currency_format_service.dart';
import '../services/date_format_service.dart';
import '../screens/expenses_list_screen.dart';

class RecentTransactionsCard extends StatelessWidget {
  final List<Expense> expenses;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final int maxItems;

  const RecentTransactionsCard({
    super.key,
    required this.expenses,
    required this.categories,
    required this.paymentMethods,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sorted.take(maxItems).toList();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and View More button
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF607D8B)),
                const SizedBox(width: 8),
                Text(
                  'recent_transactions'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExpensesListScreen(),
                      ),
                    );
                  },
                  child: Text('view_more'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Scrollable list of recent items
            Expanded(
              child: recent.isEmpty
                  ? Center(
                      child: Text('no_expenses_to_display'.tr()),
                    )
                  : ListView.separated(
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, idx) {
                        final e = recent[idx];
                        final category = categories.firstWhere(
                          (c) => c.id == e.categoryId,
                          orElse: () => Category(id: '', name: 'Unknown'),
                        );
                        final paymentMethod = paymentMethods.firstWhere(
                          (a) => a.id == e.paymentMethodId,
                          orElse: () => PaymentMethod(id: '', name: 'Unknown'),
                        );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.category,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 2),
                                      Text(category.name,
                                          style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Icon(Icons.credit_card,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 2),
                                      Text(paymentMethod.name,
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.place,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 2),
                                      Text(e.place,
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatService.formatCurrency(
                                      e.value, context),
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatService.formatDate(e.date, context),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
