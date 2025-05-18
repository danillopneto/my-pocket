// Dashboard screen with summary and charts
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment-method.dart';
import '../widgets/summary_header.dart';
import '../services/user_preferences_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';
import '../widgets/charts/payment_method_donut_chart.dart';
import '../widgets/charts/category_donut_chart.dart';
import '../widgets/charts/date_bar_chart.dart';
import '../widgets/charts/generic_bar_chart.dart';
import '../../services/currency_format_service.dart';
import '../widgets/dashboard_expense_filter.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final UserPreferencesService _prefsService = UserPreferencesService();

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  List<String> _filterCategoryIds = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterStartDate = DateTime(now.year, now.month, 1);
    _filterEndDate = now;
  }

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      return FutureBuilder<UserPreferences>(
        future: _prefsService.getPreferences(user.uid),
        builder: (context, prefsSnap) {
          final userPrefs = prefsSnap.data;
          return StreamBuilder<List<Category>>(
            stream: _firestoreService.getCategories(user.uid),
            builder: (context, catSnap) {
              if (!catSnap.hasData) {
                return const AppLoadingIndicator();
              }
              final categories = List<Category>.from(catSnap.data!)
                ..sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              return StreamBuilder<List<PaymentMethod>>(
                stream: _firestoreService.getPaymentMethods(user.uid),
                builder: (context, accSnap) {
                  if (!accSnap.hasData) {
                    return const AppLoadingIndicator();
                  }
                  final paymentMethods = List<PaymentMethod>.from(accSnap.data!)
                    ..sort((a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  return StreamBuilder<List<Expense>>(
                    stream: _firestoreService.getExpenses(
                      user.uid,
                      startDate: _filterStartDate,
                      endDate: _filterEndDate,
                      categoryIds: _filterCategoryIds.isNotEmpty
                          ? _filterCategoryIds
                          : null,
                    ),
                    builder: (context, expenseSnap) {
                      if (!expenseSnap.hasData) {
                        return const AppLoadingIndicator();
                      }
                      final allExpenses = expenseSnap.data!;
                      final expenses = allExpenses;
                      // --- Summary calculations ---
                      double total = 0;
                      double avgPerDay = 0;
                      Expense? mostExp;
                      if (expenses.isNotEmpty) {
                        total = expenses.fold(0, (sum, e) => sum + e.value);
                        // Calculate days in the selected filter range
                        if (_filterStartDate != null &&
                            _filterEndDate != null) {
                          final start = DateTime(_filterStartDate!.year,
                              _filterStartDate!.month, _filterStartDate!.day);
                          final end = DateTime(_filterEndDate!.year,
                              _filterEndDate!.month, _filterEndDate!.day);
                          final days = end.difference(start).inDays + 1;
                          avgPerDay = days > 0 ? total / days : total;
                        } else {
                          avgPerDay = total;
                        }
                        mostExp = expenses
                            .reduce((a, b) => a.value > b.value ? a : b);
                      }
                      // Extract all unique descriptions and places
                      final allDescriptions = expenses
                          .map((e) => e.description)
                          .toSet()
                          .toList()
                        ..sort();
                      final allPlaces =
                          expenses.map((e) => e.place).toSet().toList()..sort();
                      return ScaffoldWithDrawer(
                        selected: 'dashboard',
                        titleKey: 'dashboard',
                        body: ListView(
                          children: [
                            // Filter card
                            DashboardExpenseFilter(
                              categories: categories,
                              initialStartDate: _filterStartDate,
                              initialEndDate: _filterEndDate,
                              initialCategoryIds: _filterCategoryIds,
                              onApply: (start, end, categoryIds) {
                                setState(() {
                                  _filterStartDate = start;
                                  _filterEndDate = end;
                                  _filterCategoryIds = categoryIds;
                                });
                              },
                            ),
                            // Summary header
                            SummaryHeader(
                              total: total,
                              avgPerMonth: avgPerDay, // Pass as avgPerDay now
                              mostExp: mostExp,
                              categories: categories,
                              paymentMethods: paymentMethods,
                              userPrefs: userPrefs,
                              avgLabelKey:
                                  'daily_average', // Add this prop for label
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
                            // --- Split donut charts into separate cards ---

                            // Payment Method Donut Chart Card
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
                                    Row(
                                      children: [
                                        const Icon(Icons.pie_chart,
                                            color: Color(0xFF3366CC)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'expenses_by_payment_method'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Remove SizedBox(height: 300) and use chart directly
                                    PaymentMethodDonutChart(
                                      paymentMethods: paymentMethods,
                                      expenses: expenses,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Category Donut Chart Card
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
                                    Row(
                                      children: [
                                        const Icon(Icons.pie_chart,
                                            color: Color(0xFF3366CC)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'expenses_by_category'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Remove SizedBox(height: 300) and use chart directly
                                    CategoryDonutChart(
                                      categories: categories,
                                      expenses: expenses,
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
                                  ],
                                ),
                              ),
                            ),

                            // Description bar chart in its own card/section
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
                                    Row(
                                      children: [
                                        const Icon(Icons.list_alt,
                                            color: Color(0xFF607D8B)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'expenses_by_description'.tr(),
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
                                    // Remove titleKey from GenericBarChart for description chart, since the card already has the title
                                    SizedBox(
                                      height: 320,
                                      child: GenericBarChart<String>(
                                        items: allDescriptions,
                                        expenses: expenses,
                                        getId: (desc) => desc,
                                        getName: (desc) => desc,
                                        formatValue: (v, ctx) =>
                                            CurrencyFormatService
                                                .formatCurrency(v, ctx),
                                        getExpenseKey: (e) => e.description,
                                        getExpenseValue: (e) => e.value,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Place bar chart in its own card/section
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
                                    Row(
                                      children: [
                                        const Icon(Icons.place,
                                            color: Color(0xFF9C27B0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'expenses_by_place'.tr(),
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
                                    // Use GenericBarChart for top 10 expenses by place
                                    SizedBox(
                                      height: 320,
                                      child: GenericBarChart<String>(
                                        items: allPlaces,
                                        expenses: expenses,
                                        getId: (place) => place,
                                        getName: (place) => place,
                                        formatValue: (v, ctx) =>
                                            CurrencyFormatService
                                                .formatCurrency(v, ctx),
                                        getExpenseKey: (e) => e.place,
                                        getExpenseValue: (e) => e.value,
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
