import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../services/date_format_service.dart';
import '../utils/firebase_user_utils.dart';

class ItemSearchWidget extends StatefulWidget {
  final String searchQuery;
  final VoidCallback? onClose;

  const ItemSearchWidget({
    super.key,
    required this.searchQuery,
    this.onClose,
  });

  @override
  State<ItemSearchWidget> createState() => _ItemSearchWidgetState();
}

class _ItemSearchWidgetState extends State<ItemSearchWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  Expense? _lastExpense;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchLastPurchase();
  }

  @override
  void didUpdateWidget(ItemSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchLastPurchase();
    }
  }

  void _searchLastPurchase() async {
    if (widget.searchQuery.trim().isEmpty) {
      setState(() {
        _loading = false;
        _lastExpense = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await withCurrentUserAsync((user) async {
        final expense = await _firestoreService.getLastExpenseWithItem(
          user.uid,
          widget.searchQuery,
        );

        if (mounted) {
          setState(() {
            _lastExpense = expense;
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'when_last_bought'.tr(args: [widget.searchQuery]),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Text(
                'Error: $_error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else if (_lastExpense != null)
              _buildLastPurchaseInfo()
            else
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No previous purchases found for "${widget.searchQuery}"',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastPurchaseInfo() {
    final expense = _lastExpense!;
    final daysSince = DateTime.now().difference(expense.date).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'last_purchased'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatService.formatDate(expense.date, context),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '($daysSince ${daysSince == 1 ? 'day' : 'days'} ago)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'at ${expense.place}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'in "${expense.description}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
