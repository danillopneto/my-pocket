import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../services/firestore_service.dart';
import '../services/expenses_service.dart';
import '../services/entity_data_provider.dart';
import '../widgets/scaffold_with_drawer.dart';
import '../widgets/expense_form.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/snackbar_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final ExpensesService _expensesService;
  late final EntityDataProvider<Category> _categoryProvider;
  late final EntityDataProvider<PaymentMethod> _paymentMethodProvider;

  List<Category> _categories = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // Initialize services with shared firestore service instance
    _expensesService = ExpensesService(firestoreService: _firestoreService);
    _categoryProvider = EntityDataProvider<Category>(
      firestoreService: _firestoreService,
      entityType: 'categories',
    );
    _paymentMethodProvider = EntityDataProvider<PaymentMethod>(
      firestoreService: _firestoreService,
      entityType: 'paymentMethods',
    );

    _loadEntities();
  }

  Future<void> _loadEntities() async {
    try {
      final categories = await _categoryProvider.fetchEntities();
      final paymentMethods = await _paymentMethodProvider.fetchEntities();

      if (mounted) {
        setState(() {
          _categories = categories;
          _paymentMethods = paymentMethods;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        showAppSnackbar(
          context,
          'error_loading_data'.tr(),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _handleSubmit(Expense expense) async {
    try {
      await _expensesService.upsertExpense(context, expense, expense);
      if (mounted) {
        showAppSnackbar(
          context,
          'expense_added_successfully'.tr(),
          backgroundColor: Colors.green,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(
          context,
          'error_adding_expense'.tr(),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      if (_loading) {
        return ScaffoldWithDrawer(
          selected: 'add-expense',
          titleKey: 'add_expense',
          body: const AppLoadingIndicator(),
        );
      }

      // Show error message if no categories or payment methods
      if (_categories.isEmpty || _paymentMethods.isEmpty) {
        return ScaffoldWithDrawer(
          selected: 'add-expense',
          titleKey: 'add_expense',
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'missing_categories_or_payment_methods'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'please_add_categories_and_payment_methods_first'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_categories.isEmpty)
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/categories'),
                          icon: const Icon(Icons.category),
                          label: Text('categories'.tr()),
                        ),
                      if (_paymentMethods.isEmpty)
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/payment-methods'),
                          icon: const Icon(Icons.account_balance_wallet),
                          label: Text('payment_methods'.tr()),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Create new expense with default values
      final newExpense = Expense(
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
        itemNames: null,
      );

      return ScaffoldWithDrawer(
        selected: 'add-expense',
        titleKey: 'add_expense',
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ExpenseForm(
                  onSubmit: _handleSubmit,
                  initial: newExpense,
                  categories: _categories,
                  paymentMethods: _paymentMethods,
                ),
              ),
            ),
          ),
        ),
      );
    });

    return result ??
        Scaffold(
          appBar: AppBar(title: Text('add_expense'.tr())),
          body: Center(child: Text('login'.tr())),
        );
  }
}
