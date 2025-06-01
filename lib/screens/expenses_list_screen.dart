// Expenses list screen with filters
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../services/user_preferences_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/edit_expense_dialog.dart';
import '../services/expenses_service.dart';
import '../widgets/expenses_list.dart';
import '../services/entity_data_provider.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';
import '../widgets/dashboard_expense_filter.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ExpensesService _expensesService =
      ExpensesService(firestoreService: FirestoreService());
  final UserPreferencesService _prefsService = UserPreferencesService();
  final EntityDataProvider<Category> _categoryProvider =
      EntityDataProvider<Category>(
    firestoreService: FirestoreService(),
    entityType: 'categories',
  );
  final EntityDataProvider<PaymentMethod> _paymentMethodProvider =
      EntityDataProvider<PaymentMethod>(
    firestoreService: FirestoreService(),
    entityType: 'paymentMethods',
  );
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  List<String> _filterCategoryIds = [];
  List<Category> _categories = [];
  List<PaymentMethod> _paymentMethods = [];
  UserPreferences? _userPrefs;
  final List<String> _pendingDeleteIds = [];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    _loadEntities();
    _loadUserPrefs();
    final now = DateTime.now();
    _filterStartDate = now.subtract(Duration(days: 30));
    _filterEndDate = now;

    // Add search listener
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.trim().isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _loadEntities() async {
    final cats = await _categoryProvider.fetchEntities();
    final accs = await _paymentMethodProvider.fetchEntities();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _paymentMethods = accs;
    });
  }

  void _loadUserPrefs() async {
    await withCurrentUserAsync((user) async {
      final prefs = await _prefsService.getPreferences(user.uid);
      if (!mounted) return;
      setState(() => _userPrefs = prefs);
    });
  }

  void _editExpenseDialog(Expense expense) async {
    showDialog(
      context: context,
      builder: (context) {
        return EditExpenseDialog(
          expense: expense,
          categories: _categories,
          paymentMethods: _paymentMethods,
          isNew: false,
          onSubmit: (edited) async {
            await _expensesService.upsertExpense(context, expense, edited);
          },
        );
      },
    );
  }

  void _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(),
    );
    if (!mounted) return;
    if (confirm != true) return;

    setState(() {
      _pendingDeleteIds.add(expense.id!);
    });

    final wasDeleted = await _expensesService.deleteExpenseWithUndo(
      context: context,
      expense: expense,
      pendingDeleteIds: _pendingDeleteIds,
      onLocalUpdate: () {
        if (mounted) setState(() {});
      },
    );

    if (!mounted) return;
    setState(() {
      _pendingDeleteIds.remove(expense.id!);
    });

    // Only show success message if actually deleted
    if (wasDeleted) {
      showAppSnackbar(context, 'expense_deleted'.tr(),
          backgroundColor: Colors.green);
    }
    // No need to reload, stream will update
  }

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      return ScaffoldWithDrawer(
        selected: 'expenses-list',
        titleKey: 'expenses_list',
        body: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search_items'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            // Filter card (show only when not searching)
            if (!_isSearching)
              DashboardExpenseFilter(
                categories: _categories,
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
            Expanded(
              child: StreamBuilder<List<Expense>>(
                stream: _isSearching
                    ? _firestoreService.searchExpensesAll(
                        user.uid,
                        _searchQuery,
                        startDate: _filterStartDate,
                        endDate: _filterEndDate,
                        limit: 100,
                      )
                    : _firestoreService.getExpenses(
                        user.uid,
                        startDate: _filterStartDate,
                        endDate: _filterEndDate,
                        categoryIds: _filterCategoryIds.isNotEmpty
                            ? _filterCategoryIds
                            : null,
                      ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator();
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(_isSearching
                          ? 'no_results_found'.tr()
                          : 'no_expenses_found'.tr()),
                    );
                  }
                  var expenses = snapshot.data!;
                  // Filter out pending deletes
                  expenses = expenses
                      .where((e) => !_pendingDeleteIds.contains(e.id))
                      .toList();

                  if (expenses.isEmpty) {
                    return Center(
                      child: Text(_isSearching
                          ? 'no_results_found'.tr()
                          : 'no_expenses_found'.tr()),
                    );
                  }

                  return ExpensesList(
                    expenses: expenses,
                    categories: _categories,
                    paymentMethods: _paymentMethods,
                    onEdit: _editExpenseDialog,
                    onDelete: _deleteExpense,
                    showTotal: true,
                    currencySymbolOverride: _userPrefs?.currencySymbol,
                    currencyFormatOverride: _userPrefs?.currencyFormat,
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
    return result ??
        Scaffold(
          appBar: AppBar(
              title: Builder(builder: (context) => Text('expenses_list'.tr()))),
          drawer: AppDrawer(selected: 'expenses-list'),
          body: Center(child: Text('login'.tr())),
        );
  }
}
