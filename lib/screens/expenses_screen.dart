// Expenses add/edit screen
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/expenses_service.dart';
import '../widgets/edit_expense_dialog.dart';
import '../widgets/expenses_list.dart';
import '../services/entity_data_provider.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ExpensesService _expensesService =
      ExpensesService(firestoreService: FirestoreService());
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
  final bool _loading = false;
  List<Category> _categories = [];
  List<PaymentMethod> _paymentMethods = [];
  List<Expense> _recentExpenses = [];
  final List<String> _pendingDeleteIds = [];

  @override
  void initState() {
    super.initState();
    _loadEntities();
    _loadRecentExpenses();
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

  void _loadRecentExpenses() {
    withCurrentUserAsync((user) async {
      _firestoreService.getExpenses(user.uid).listen((expenses) {
        if (!mounted) return;
        setState(() => _recentExpenses = expenses
            .where((e) => !_pendingDeleteIds.contains(e.id))
            .take(5)
            .toList());
      });
    });
  }

  void _openEditExpenseDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => EditExpenseDialog(
        expense: expense,
        categories: _categories,
        paymentMethods: _paymentMethods,
        isNew: false,
        onSubmit: (edited) async {
          await _expensesService.upsertExpense(context, expense, edited);
          if (!context.mounted) return;
          Navigator.of(context).pop();
          _loadRecentExpenses();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('expense_added'.tr())),
          );
        },
      ),
    );
  }

  void _openAddExpenseDialog() {
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
          categoryId: _categories.isNotEmpty ? _categories.first.id ?? '' : '',
          paymentMethodId:
              _paymentMethods.isNotEmpty ? _paymentMethods.first.id ?? '' : '',
          itemNames: null, // New expenses start with no items
        ),
        categories: _categories,
        paymentMethods: _paymentMethods,
        isNew: true,
        onSubmit: (expense) async {
          await _expensesService.upsertExpense(context, expense, expense);
          if (!context.mounted) return;
          Navigator.of(context).pop();
          _loadRecentExpenses();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('expense_added'.tr())),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      return ScaffoldWithDrawer(
        selected: 'expenses',
        titleKey: 'expenses',
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('recent_expenses'.tr(),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ExpensesList(
                expenses: _recentExpenses,
                categories: _categories,
                paymentMethods: _paymentMethods,
                onEdit: _openEditExpenseDialog,
                onDelete: (expense) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => ConfirmDeleteDialog(),
                  );
                  if (confirm != true) return;
                  setState(() {
                    _pendingDeleteIds.add(expense.id!);
                  });
                  await _expensesService.deleteExpenseWithUndo(
                    context: context,
                    expense: expense,
                    pendingDeleteIds: _pendingDeleteIds,
                    onLocalUpdate: () => setState(() {}),
                  );
                  if (!context.mounted) return;
                  setState(() {
                    _pendingDeleteIds.remove(expense.id!);
                  });
                  _loadRecentExpenses();
                  showAppSnackbar(context, 'expense_deleted'.tr(),
                      backgroundColor: Colors.green);
                },
                showTotal: false,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: AppLoadingIndicator(),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddExpenseDialog,
          tooltip: 'add_expense'.tr(),
          child: const Icon(Icons.add),
        ),
      );
    });
    return result ??
        Scaffold(
          appBar: AppBar(title: Text('expenses'.tr())),
          body: Center(child: Text('login'.tr())),
        );
  }
}
