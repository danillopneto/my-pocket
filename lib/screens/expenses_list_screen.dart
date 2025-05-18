// Expenses list screen with filters
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment-method.dart';
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
  final EntityDataProvider<PaymentMethod> _payment_methodProvider =
      EntityDataProvider<PaymentMethod>(
    firestoreService: FirestoreService(),
    entityType: 'paymentMethods',
  );
  String _filterText = '';
  List<Category> _categories = [];
  List<PaymentMethod> _payment_methods = [];
  UserPreferences? _userPrefs;
  final List<String> _pendingDeleteIds = [];

  @override
  void initState() {
    super.initState();
    _loadEntities();
    _loadUserPrefs();
  }

  void _loadEntities() async {
    final cats = await _categoryProvider.fetchEntities();
    final accs = await _payment_methodProvider.fetchEntities();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _payment_methods = accs;
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
          paymentMethods: _payment_methods,
          isNew: false,
          onSubmit: (edited) async {
            await _expensesService.updateExpense(context, expense, edited);
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
    await _expensesService.deleteExpenseWithUndo(
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
    showAppSnackbar(context, 'expense_deleted'.tr(),
        backgroundColor: Colors.green);
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'filter'.tr(),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _filterText = value);
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Expense>>(
                stream: _firestoreService.getExpenses(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('no_expenses_found'.tr()));
                  }
                  var expenses = snapshot.data!;
                  // Filter out pending deletes
                  expenses = expenses
                      .where((e) => !_pendingDeleteIds.contains(e.id))
                      .toList();
                  if (_filterText.isNotEmpty) {
                    expenses = expenses
                        .where((e) =>
                            e.description
                                .toLowerCase()
                                .contains(_filterText.toLowerCase()) ||
                            e.place
                                .toLowerCase()
                                .contains(_filterText.toLowerCase()))
                        .toList();
                  }
                  return ExpensesList(
                    expenses: expenses,
                    categories: _categories,
                    paymentMethods: _payment_methods,
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
