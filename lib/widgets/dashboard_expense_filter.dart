// Widget for filtering expenses by date range and category
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../models/category.dart';
import '../services/date_format_service.dart';

class DashboardExpenseFilter extends StatefulWidget {
  final List<Category> categories;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<String>? initialCategoryIds;
  final void Function(DateTime? start, DateTime? end, List<String> categoryIds)
      onApply;

  const DashboardExpenseFilter({
    super.key,
    required this.categories,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCategoryIds,
    required this.onApply,
  });

  @override
  State<DashboardExpenseFilter> createState() => _DashboardExpenseFilterState();
}

class _DashboardExpenseFilterState extends State<DashboardExpenseFilter> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _categoryIds = [];

  @override
  void initState() {
    super.initState();
    // If initialStartDate or initialEndDate are not provided, use widget values (first day of month to today)
    if (widget.initialStartDate == null || widget.initialEndDate == null) {
      final now = DateTime.now();
      _startDate = widget.initialStartDate ?? DateTime(now.year, now.month, 1);
      _endDate = widget.initialEndDate ?? now;
    } else {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
    }
    _categoryIds = widget.initialCategoryIds ?? [];
  }

  void _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      // No immediate apply
    }
  }

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      _startDate = widget.initialStartDate ?? DateTime(now.year, now.month, 1);
      _endDate = widget.initialEndDate ?? now;
      _categoryIds = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('filter'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'date_start'.tr(),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(_startDate != null
                          ? DateFormatService.formatDate(_startDate!, context)
                          : '-'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'date_end'.tr(),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(_endDate != null
                          ? DateFormatService.formatDate(_endDate!, context)
                          : '-'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MultiSelectDialogField<String>(
              items: widget.categories
                  .map((cat) => MultiSelectItem(cat.id!, cat.name))
                  .toList(),
              initialValue: _categoryIds,
              title: Text('category'.tr()),
              buttonText: Text(_categoryIds.isEmpty
                  ? 'all_categories'.tr()
                  : widget.categories
                      .where((c) => _categoryIds.contains(c.id))
                      .map((c) => c.name)
                      .join(', ')),
              searchable: true,
              listType: MultiSelectListType.CHIP,
              onConfirm: (values) {
                if (values.length > 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('category_limit_warning'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setState(() => _categoryIds = values);
                // No immediate apply
              },
              chipDisplay: MultiSelectChipDisplay.none(),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: Text('reset'.tr()),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(_startDate, _endDate, _categoryIds);
                  },
                  child: Text('apply'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
