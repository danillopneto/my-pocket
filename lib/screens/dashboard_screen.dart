// Dashboard screen with summary and charts
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
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
import '../widgets/recent_transactions_card.dart';
import '../services/currency_format_service.dart';
import '../widgets/dashboard_expense_filter.dart';
import '../widgets/dashboard_search_card.dart';
import '../services/expenses_service.dart';
import '../widgets/edit_expense_dialog.dart';
import '../services/analyze_expenses_service.dart';
import '../services/summary_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final UserPreferencesService _prefsService = UserPreferencesService();
  final SummaryService _summaryService = SummaryService();

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  List<String> _filterCategoryIds = [];
  // Track which chart is visible: true for payment method, false for category
  bool _showPaymentMethodChart = false;
  // Track which bar chart is visible: 0 = date, 1 = description, 2 = place
  int _activeBarChartIndex = 0;

  String? _aiAnalysisResult;
  bool _aiAnalysisLoading = false;
  String? _aiAnalysisError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterStartDate = now.subtract(Duration(days: 30));
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
                      final expenses = expenseSnap.data!;
                      // --- Summary calculations ---
                      final summary = _summaryService.calculateSummary(
                        expenses,
                        startDate: _filterStartDate,
                        endDate: _filterEndDate,
                      );
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
                                  _aiAnalysisResult = null;
                                  _aiAnalysisError = null;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Quick search card
                            const DashboardSearchCard(),
                            const SizedBox(height: 24),
                            // --- Analyze with AI button and result ---
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Only show the button if there's no result yet and not loading
                                if (_aiAnalysisResult == null &&
                                    !_aiAnalysisLoading)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.auto_awesome),
                                    label: Text('analyze_with_ai'.tr()),
                                    onPressed: () async {
                                      setState(() {
                                        _aiAnalysisLoading = true;
                                        _aiAnalysisResult = null;
                                        _aiAnalysisError = null;
                                      });
                                      try {
                                        final service =
                                            AnalyzeExpensesService();
                                        final result =
                                            await service.analyzeExpenses(
                                          expenses,
                                          categories: categories,
                                          paymentMethods: paymentMethods,
                                          summary: summary,
                                        );
                                        setState(() {
                                          _aiAnalysisResult = result;
                                          _aiAnalysisLoading = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          _aiAnalysisError = 'ai_analysis_error'
                                              .tr(args: [e.toString()]);
                                          _aiAnalysisLoading = false;
                                        });
                                      }
                                    },
                                  ),
                                if (_aiAnalysisLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12.0),
                                    child: AppLoadingIndicator(),
                                  ),
                                if (_aiAnalysisError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Text(
                                      _aiAnalysisError!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    ),
                                  ),
                                if (_aiAnalysisResult != null &&
                                    !_aiAnalysisLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Card(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          _aiAnalysisResult!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Summary header
                            SummaryHeader(
                              summary: summary,
                              userPrefs: userPrefs,
                            ),
                            const SizedBox(height: 24),
                            // --- Donut chart section segmented control ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Custom segmented control to toggle between charts
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Category tab
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showPaymentMethodChart = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: !_showPaymentMethodChart
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            'categories'.tr(),
                                            style: TextStyle(
                                              color: !_showPaymentMethodChart
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Payment Method tab
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showPaymentMethodChart = true;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _showPaymentMethodChart
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            'payment_methods'.tr(),
                                            style: TextStyle(
                                              color: _showPaymentMethodChart
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ), // Responsive layout for donut chart and recent transactions
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Use mobile layout for screens smaller than 600px width
                                final isMobile = constraints.maxWidth < 600;

                                if (isMobile) {
                                  // Mobile layout: stack vertically
                                  return Column(
                                    children: [
                                      // Donut Chart (full width on mobile)
                                      Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.pie_chart,
                                                      color: Color(0xFF3366CC)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _showPaymentMethodChart
                                                        ? 'expenses_by_payment_method'
                                                            .tr()
                                                        : 'expenses_by_category'
                                                            .tr(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              // Conditionally show the appropriate chart
                                              _showPaymentMethodChart
                                                  ? PaymentMethodDonutChart(
                                                      paymentMethods:
                                                          paymentMethods,
                                                      expenses: expenses,
                                                    )
                                                  : CategoryDonutChart(
                                                      categories: categories,
                                                      expenses: expenses,
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ), // Recent Transactions (full width below chart on mobile)
                                      RecentTransactionsCard(
                                        categories: categories,
                                        paymentMethods: paymentMethods,
                                        maxItems:
                                            5, // Show top 5 most recent transactions
                                      ),
                                    ],
                                  );
                                } else {
                                  // Desktop layout: side by side
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Left side - Donut Chart (60% width)
                                      Expanded(
                                        flex: 6,
                                        child: Card(
                                          margin: const EdgeInsets.all(16),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.pie_chart,
                                                        color:
                                                            Color(0xFF3366CC)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _showPaymentMethodChart
                                                          ? 'expenses_by_payment_method'
                                                              .tr()
                                                          : 'expenses_by_category'
                                                              .tr(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                // Conditionally show the appropriate chart
                                                _showPaymentMethodChart
                                                    ? PaymentMethodDonutChart(
                                                        paymentMethods:
                                                            paymentMethods,
                                                        expenses: expenses,
                                                      )
                                                    : CategoryDonutChart(
                                                        categories: categories,
                                                        expenses: expenses,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Right side - Recent Transactions (40% width)
                                      Expanded(
                                        flex: 4,
                                        child: SizedBox(
                                          height:
                                              400, // Fixed height for the container
                                          child: RecentTransactionsCard(
                                            categories: categories,
                                            paymentMethods: paymentMethods,
                                            maxItems:
                                                5, // Show top 5 most recent transactions
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            // Bar chart section - with toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Custom segmented control to toggle between bar charts
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Date tab
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _activeBarChartIndex = 0;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _activeBarChartIndex == 0
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            'date'.tr(),
                                            style: TextStyle(
                                              color: _activeBarChartIndex == 0
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Description tab
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _activeBarChartIndex = 1;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _activeBarChartIndex == 1
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            'description'.tr(),
                                            style: TextStyle(
                                              color: _activeBarChartIndex == 1
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Place tab
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _activeBarChartIndex = 2;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _activeBarChartIndex == 2
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Text(
                                            'place'.tr(),
                                            style: TextStyle(
                                              color: _activeBarChartIndex == 2
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Single Bar Chart Card (switches between the charts)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Dynamic chart header based on selection
                                    Row(
                                      children: [
                                        Icon(
                                          _activeBarChartIndex == 0
                                              ? Icons.bar_chart
                                              : (_activeBarChartIndex == 1
                                                  ? Icons.list_alt
                                                  : Icons.place),
                                          color: _activeBarChartIndex == 0
                                              ? const Color(0xFF4CAF50)
                                              : (_activeBarChartIndex == 1
                                                  ? const Color(0xFF607D8B)
                                                  : const Color(0xFF9C27B0)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _activeBarChartIndex == 0
                                              ? 'expenses_by_date'.tr()
                                              : (_activeBarChartIndex == 1
                                                  ? 'expenses_by_description'
                                                      .tr()
                                                  : 'expenses_by_place'.tr()),
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

                                    // Conditionally show the selected chart
                                    if (_activeBarChartIndex == 0)
                                      SizedBox(
                                        height: 280,
                                        child: DateBarChart(
                                          expenses: expenses,
                                        ),
                                      )
                                    else if (_activeBarChartIndex == 1)
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
                                      )
                                    else
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
                          ], // <-- This closes the ListView children
                        ), // <-- This closes the ListView
                        // add FAB for adding expenses
                        floatingActionButton: FloatingActionButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditExpenseDialog(
                                expense: Expense(
                                  id: null,
                                  date: DateTime.now(),
                                  createdAt: DateTime.now(),
                                  description: '',
                                  value: 0,
                                  installments: 1,
                                  place: '',
                                  categoryId: categories.isNotEmpty
                                      ? categories.first.id ?? ''
                                      : '',
                                  paymentMethodId: paymentMethods.isNotEmpty
                                      ? paymentMethods.first.id ?? ''
                                      : '',
                                  itemNames:
                                      null, // New expenses start with no items
                                ),
                                categories: categories,
                                paymentMethods: paymentMethods,
                                isNew: true,
                                onSubmit: (expense) async {
                                  await ExpensesService(
                                          firestoreService: _firestoreService)
                                      .upsertExpense(context, expense, expense);
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                          tooltip: 'add_expense'.tr(),
                          child: const Icon(Icons.add),
                        ),
                      ); // <-- This closes ScaffoldWithDrawer
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
