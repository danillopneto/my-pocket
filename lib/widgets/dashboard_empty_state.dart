// Dashboard empty state widget for when user has no expenses
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/category.dart';
import '../models/payment_method.dart';

class DashboardEmptyState extends StatelessWidget {
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  final VoidCallback onAddExpense;

  const DashboardEmptyState({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome illustration/icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Welcome title
            Text(
              'welcome_to_dashboard'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // No expenses message
            Text(
              'no_expenses_yet'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8), // Get started message
            Text(
              categories.isEmpty || paymentMethods.isEmpty
                  ? 'setup_categories_and_payment_methods'.tr()
                  : 'get_started_message'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Show setup requirements prominently if categories or payment methods are empty
            if (categories.isEmpty || paymentMethods.isEmpty) ...[
              Card(
                elevation: 3,
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: colorScheme.onErrorContainer,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'setup_required_title'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'setup_required_message'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Setup buttons
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          if (categories.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/categories');
                              },
                              icon: const Icon(Icons.category_outlined),
                              label: Text('manage_categories'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                            ),
                          if (paymentMethods.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed('/payment-methods');
                              },
                              icon: const Icon(Icons.payment),
                              label: Text('manage_payment_methods'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Add expense button (only show when setup is complete)
              ElevatedButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add),
                label: Text('add_your_first_expense'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Optional setup suggestions if everything is ready
            if (categories.isNotEmpty && paymentMethods.isNotEmpty) ...[
              Card(
                elevation: 1,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'setup_categories_and_payment_methods'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Additional setup buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/categories');
                            },
                            icon: const Icon(Icons.category_outlined),
                            label: Text('manage_categories'.tr()),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/payment-methods');
                            },
                            icon: const Icon(Icons.payment),
                            label: Text('manage_payment_methods'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
