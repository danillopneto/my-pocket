import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/firestore_service.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../widgets/expenses_list.dart';
import '../utils/firebase_user_utils.dart';
import '../services/entity_data_provider.dart';

class DashboardSearchCard extends StatefulWidget {
  const DashboardSearchCard({super.key});

  @override
  State<DashboardSearchCard> createState() => _DashboardSearchCardState();
}

class _DashboardSearchCardState extends State<DashboardSearchCard> {
  final TextEditingController _searchController = TextEditingController();
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
  String _searchQuery = '';
  bool _isExpanded = false;
  List<Category> _categories = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _entitiesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEntities() async {
    final cats = await _categoryProvider.fetchEntities();
    final payMethods = await _paymentMethodProvider.fetchEntities();
    if (mounted) {
      setState(() {
        _categories = cats;
        _paymentMethods = payMethods;
        _entitiesLoaded = true;
      });
    }
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _searchQuery = query.trim();
      if (_searchQuery.isNotEmpty) {
        _isExpanded = true;
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'search_expenses'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_items_description_place'.tr(),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              onSubmitted: _onSearchSubmitted,
              onChanged: (value) {
                if (value.trim().isEmpty && _searchQuery.isNotEmpty) {
                  _clearSearch();
                }
              },
            ),
          ), // Search results
          if (_isExpanded && _searchQuery.isNotEmpty) ...[
            // Search results header
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'search_results'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close, size: 16),
                    label: Text('close'.tr()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            // Actual search results
            if (_entitiesLoaded)
              SizedBox(
                height: 300, // Fixed height for results
                child: withCurrentUser<Widget>((user) {
                      return StreamBuilder<List<Expense>>(
                        stream: _firestoreService.searchExpensesAll(
                          user.uid,
                          _searchQuery,
                          limit: 20, // Limit results for dashboard
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('no_results_found'.tr()),
                              ),
                            );
                          }

                          final expenses = snapshot.data!;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ExpensesList(
                              expenses: expenses,
                              categories: _categories,
                              paymentMethods: _paymentMethods,
                              showTotal: true,
                              isCompact: true,
                            ),
                          );
                        },
                      );
                    }) ??
                    const SizedBox.shrink(),
              ),
          ],
        ],
      ),
    );
  }
}
