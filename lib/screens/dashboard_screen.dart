// Dashboard screen with summary and charts
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../widgets/summary_header.dart';
import '../services/user_preferences_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';
import '../widgets/charts/account_donut_chart.dart';
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/charts/date_bar_chart.dart';
import '../widgets/charts/description_bar_chart.dart';

class DashboardScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final UserPreferencesService _prefsService = UserPreferencesService();

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      return FutureBuilder<UserPreferences>(
        future: _prefsService.getPreferences(user.uid),
        builder: (context, prefsSnap) {
          final userPrefs = prefsSnap.data;
          return StreamBuilder<List<Expense>>(
            stream: _firestoreService.getExpenses(user.uid),
            builder: (context, expenseSnap) {
              if (!expenseSnap.hasData) {
                return const AppLoadingIndicator();
              }
              final expenses = expenseSnap.data!;
              return StreamBuilder<List<Category>>(
                stream: _firestoreService.getCategories(user.uid),
                builder: (context, catSnap) {
                  if (!catSnap.hasData) {
                    return const AppLoadingIndicator();
                  }
                  final categories = List<Category>.from(catSnap.data!)
                    ..sort((a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  return StreamBuilder<List<Account>>(
                    stream: _firestoreService.getAccounts(user.uid),
                    builder: (context, accSnap) {
                      if (!accSnap.hasData) {
                        return const AppLoadingIndicator();
                      }
                      final accounts = List<Account>.from(accSnap.data!)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase()));
                      // --- Summary calculations ---
                      double total = 0;
                      double avgPerMonth = 0;
                      Expense? mostExp;
                      if (expenses.isNotEmpty) {
                        total = expenses.fold(0, (sum, e) => sum + e.value);
                        final months = expenses
                            .map((e) => DateTime(e.date.year, e.date.month))
                            .toSet()
                            .length;
                        avgPerMonth = months > 0 ? total / months : total;
                        mostExp = expenses
                            .reduce((a, b) => a.value > b.value ? a : b);
                      }
                      return ScaffoldWithDrawer(
                        selected: 'dashboard',
                        titleKey: 'dashboard',
                        body: ListView(
                          // Removed redundant padding, now handled by ScaffoldWithDrawer
                          children: [
                            // Summary header
                            SummaryHeader(
                              total: total,
                              avgPerMonth: avgPerMonth,
                              mostExp: mostExp,
                              categories: categories,
                              accounts: accounts,
                              userPrefs: userPrefs,
                            ),
                            const SizedBox(height: 24),

                            // Dashboard title
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'dashboard_charts'.tr(),
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Donut chart section - side by side
                            Card(
                              margin: const EdgeInsets.all(16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Distribution section header
                                    Row(
                                      children: [
                                        const Icon(Icons.pie_chart,
                                            color: Color(0xFF3366CC)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'distribution'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Two donut charts side by side
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Use row for wider screens, column for narrower ones
                                        return constraints.maxWidth > 600
                                            ? Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Account donut chart
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'expenses_by_account'
                                                                .tr(),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleSmall),
                                                        const SizedBox(
                                                            height: 12),
                                                        SizedBox(
                                                          height: 300,
                                                          child:
                                                              AccountDonutChart(
                                                            accounts: accounts,
                                                            expenses: expenses,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Category donut chart
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'expenses_by_category'
                                                                .tr(),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleSmall),
                                                        const SizedBox(
                                                            height: 12),
                                                        SizedBox(
                                                          height: 300,
                                                          child:
                                                              CategoryDonutChart(
                                                            categories:
                                                                categories,
                                                            expenses: expenses,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Account donut chart
                                                  Text(
                                                      'expenses_by_account'
                                                          .tr(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    height: 280,
                                                    child: AccountDonutChart(
                                                      accounts: accounts,
                                                      expenses: expenses,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  // Category donut chart
                                                  Text(
                                                      'expenses_by_category'
                                                          .tr(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    height: 280,
                                                    child: CategoryDonutChart(
                                                      categories: categories,
                                                      expenses: expenses,
                                                    ),
                                                  ),
                                                ],
                                              );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bar chart section
                            Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Trends header
                                    Row(
                                      children: [
                                        const Icon(Icons.bar_chart,
                                            color: Color(0xFF4CAF50)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'trends'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Date bar chart
                                    Text('expenses_by_date'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    SizedBox(
                                      height: 280,
                                      child: DateBarChart(
                                        expenses: expenses,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Description bar chart
                                    Text('expenses_by_description'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    SizedBox(
                                      height: 280,
                                      child: DescriptionBarChart(
                                        expenses: expenses,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    });
    return result ?? Center(child: Text('login'.tr()));
  }
}
