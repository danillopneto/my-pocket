import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/item_search_widget.dart';

class QuickSearchCard extends StatefulWidget {
  const QuickSearchCard({super.key});

  @override
  State<QuickSearchCard> createState() => _QuickSearchCardState();
}

class _QuickSearchCardState extends State<QuickSearchCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    'search_by_item_name'.tr(),
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
                hintText: 'search_items'.tr(),
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
          ),
          // Search results
          if (_isExpanded && _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: ItemSearchWidget(
                searchQuery: _searchQuery,
                onClose: _clearSearch,
              ),
            ),
        ],
      ),
    );
  }
}
