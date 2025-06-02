import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../services/firestore_service.dart';
import '../widgets/drawer_widget.dart';
import '../services/entity_data_provider.dart';
import '../widgets/app_loading_indicator.dart';
import '../utils/firebase_user_utils.dart';

class BulkAddExpensesScreen extends StatefulWidget {
  const BulkAddExpensesScreen({super.key});

  @override
  State<BulkAddExpensesScreen> createState() => _BulkAddExpensesScreenState();
}

class _BulkAddExpensesScreenState extends State<BulkAddExpensesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
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
  final TextEditingController controller = TextEditingController();
  bool parsing = false;
  List<List<String>> previewRows = [];
  List<Category> _categories = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(_updatePreview);
    _fetchEntities();
  }

  Future<void> _fetchEntities() async {
    final cats = await _categoryProvider.fetchEntities();
    final accs = await _paymentMethodProvider.fetchEntities();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _paymentMethods = accs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    controller.removeListener(_updatePreview);
    controller.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final pasted = controller.text.trim();
    final lines = pasted
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) {
      setState(() => previewRows = []);
      return;
    }
    final dataLines = lines.skip(1);
    final rows = <List<String>>[];
    for (final line in dataLines) {
      final cols = line.split('\t');
      if (cols.length >= 6) {
        // Validate category and paymentMethod
        final categoryValid = _categories
            .any((c) => c.name.toLowerCase() == cols[4].toLowerCase());
        final paymentMethodValid = _paymentMethods
            .any((a) => a.name.toLowerCase() == cols[5].toLowerCase());
        // Mark invalids visually
        final displayCols = List<String>.from(cols.take(6));
        if (!categoryValid) displayCols[4] = '[${displayCols[4]}]';
        if (!paymentMethodValid) displayCols[5] = '[${displayCols[5]}]';
        rows.add(displayCols);
      }
    }
    setState(() => previewRows = rows);
  }

  bool get _hasInvalidRows {
    for (final row in previewRows) {
      if ((row[4].startsWith('[')) || (row[5].startsWith('['))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('bulk_paste'.tr())),
      drawer: AppDrawer(selected: 'bulk-add-expenses'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _loading
              ? const AppLoadingIndicator()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('bulk_paste_instructions'.tr(args: [
                              'DATA\tDESCRIÇÃO\tVALOR\tLUGAR\tCATEGORIA\tCONTA',
                            ])),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller,
                              minLines: 6,
                              maxLines: 16,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'bulk_paste_hint'.tr(),
                              ),
                              enabled: !parsing,
                            ),
                            const SizedBox(height: 16),
                            if (previewRows.isNotEmpty) ...[
                              Text('Pré-visualização:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Data')),
                                    DataColumn(label: Text('Descrição')),
                                    DataColumn(label: Text('Valor')),
                                    DataColumn(label: Text('Lugar')),
                                    DataColumn(label: Text('Categoria')),
                                    DataColumn(label: Text('Conta')),
                                  ],
                                  rows: previewRows
                                      .map((cols) => DataRow(
                                            cells: List.generate(
                                              6,
                                              (i) => DataCell(
                                                Text(
                                                  cols[i],
                                                  style: (i == 4 &&
                                                              cols[i]
                                                                  .startsWith(
                                                                      '[')) ||
                                                          (i == 5 &&
                                                              cols[i]
                                                                  .startsWith(
                                                                      '['))
                                                      ? const TextStyle(
                                                          color: Colors.red)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: Text('add'.tr()),
                      onPressed: parsing ||
                              previewRows.isEmpty ||
                              _hasInvalidRows
                          ? null
                          : () async {
                              setState(() => parsing = true);
                              final pasted = controller.text.trim();
                              final lines = pasted
                                  .split(RegExp(r'\r?\n'))
                                  .where((l) => l.trim().isNotEmpty)
                                  .toList();
                              if (lines.length < 2) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('bulk_paste_no_data'.tr())),
                                );
                                setState(() => parsing = false);
                                return;
                              }
                              final dataLines = lines.skip(1);
                              int added = 0, failed = 0;
                              final List<Expense> validExpenses = [];
                              for (final line in dataLines) {
                                final cols = line.split('\t');
                                if (cols.length < 6) {
                                  failed++;
                                  continue;
                                }
                                try {
                                  final date =
                                      DateFormat('M/d/yyyy').parse(cols[0]);
                                  final description = cols[1];
                                  // Robust currency/decimal parsing
                                  String valueStr = cols[2]
                                      .replaceAll(RegExp(r'[^0-9.,-]'), '');
                                  // Remove all but the last period or comma (decimal separator)
                                  if (valueStr.contains(',') &&
                                      valueStr.contains('.')) {
                                    // If both, assume comma is thousands sep, period is decimal
                                    valueStr = valueStr.replaceAll(',', '');
                                  } else if (valueStr.contains(',') &&
                                      !valueStr.contains('.')) {
                                    // If only comma, treat as decimal sep (e.g., European format)
                                    valueStr = valueStr.replaceAll('.', '');
                                    valueStr = valueStr.replaceAll(',', '.');
                                  }
                                  // Remove leading zeros (except for decimals)
                                  valueStr = valueStr.replaceFirst(
                                      RegExp(r'^0+(?![.,]|$)'), '');
                                  // If empty after cleaning, fallback to 0.0
                                  final value =
                                      double.tryParse(valueStr) ?? 0.0;
                                  final place = cols[3];
                                  final categoryName = cols[4];
                                  final paymentMethodName = cols[5];
                                  final category = _categories.firstWhereOrNull(
                                      (c) =>
                                          c.name.toLowerCase() ==
                                          categoryName.toLowerCase());
                                  final paymentMethod =
                                      _paymentMethods.firstWhereOrNull((a) =>
                                          a.name.toLowerCase() ==
                                          paymentMethodName.toLowerCase());
                                  if (category == null ||
                                      paymentMethod == null) {
                                    failed++;
                                    continue;
                                  }
                                  final expense = Expense(
                                    id: null,
                                    date: date,
                                    createdAt: DateTime.now(),
                                    description: description,
                                    value: value,
                                    installments: 1,
                                    place: place,
                                    categoryId: category.id!,
                                    paymentMethodId: paymentMethod.id!,
                                    itemNames:
                                        null, // Bulk imports don't have extracted items
                                  );
                                  validExpenses.add(expense);
                                  added++;
                                } catch (e) {
                                  failed++;
                                }
                              }
                              await withCurrentUserAsync((user) async {
                                if (validExpenses.isNotEmpty) {
                                  await _firestoreService.addExpenses(
                                      user.uid, validExpenses);
                                }
                              });
                              setState(() => parsing = false);
                              if (added > 0) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('bulk_paste_result'.tr(args: [
                                      added.toString(),
                                      failed.toString()
                                    ])),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('bulk_paste_result'.tr(args: [
                                      added.toString(),
                                      failed.toString()
                                    ])),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              controller.clear();
                            },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

extension _FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
