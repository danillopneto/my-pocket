// Widget for adding/editing a single expense
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../services/date_format_service.dart';

class ExpenseForm extends StatefulWidget {
  final void Function(Expense expense) onSubmit;
  final Expense? initial;
  final List<Category> categories;
  final List<Account> accounts;
  const ExpenseForm({
    required this.onSubmit,
    this.initial,
    this.categories = const [],
    this.accounts = const [],
    super.key,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late String _description;
  late double _value;
  late int _installments;
  late String _place;
  late String _categoryId;
  late String _accountId;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _date = i?.date ?? DateTime.now();
    _description = i?.description ?? '';
    _value = i?.value ?? 0.0;
    _installments = i?.installments ?? 1;
    _place = i?.place ?? '';
    _categoryId = i?.categoryId ?? '';
    _accountId = i?.accountId ?? '';
  }

  @override
  void didUpdateWidget(covariant ExpenseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the categories/accounts list changes and the current value is not present, reset to first available
    if (widget.categories.isNotEmpty &&
        !widget.categories.any((c) => c.id == _categoryId)) {
      setState(() => _categoryId = widget.categories.first.id ?? '');
    }
    if (widget.accounts.isNotEmpty &&
        !widget.accounts.any((a) => a.id == _accountId)) {
      setState(() => _accountId = widget.accounts.first.id ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _description,
              decoration: InputDecoration(labelText: 'description'.tr()),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
              onSaved: (v) => _description = v ?? '',
            ),
            TextFormField(
              initialValue: _value == 0.0 ? '' : _value.toString(),
              decoration: InputDecoration(labelText: 'value'.tr()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]*[.,]?[0-9]*')),
              ],
              validator: (v) =>
                  v == null || double.tryParse(v.replaceAll(',', '.')) == null
                      ? 'enter_valid_number'.tr()
                      : null,
              onSaved: (v) => _value =
                  double.tryParse(v?.replaceAll(',', '.') ?? '') ?? 0.0,
            ),
            TextFormField(
              initialValue: _installments.toString(),
              decoration: InputDecoration(labelText: 'installments'.tr()),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || int.tryParse(v) == null
                  ? 'enter_valid_number'.tr()
                  : null,
              onSaved: (v) => _installments = int.tryParse(v ?? '') ?? 1,
            ),
            TextFormField(
              initialValue: _place,
              decoration: InputDecoration(labelText: 'place'.tr()),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
              onSaved: (v) => _place = v ?? '',
            ),
            // Date picker field with icon on the right
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'date'.tr(),
                        border: UnderlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(
                        DateFormatService.formatDate(_date, context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: InputDecoration(labelText: 'category'.tr()),
              items: widget.categories
                  .map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
              onSaved: (v) => _categoryId = v ?? '',
            ),
            DropdownButtonFormField<String>(
              value: widget.accounts.any((a) => a.id == _accountId)
                  ? _accountId
                  : null,
              decoration: InputDecoration(labelText: 'account'.tr()),
              items: widget.accounts
                  .map((acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
              onSaved: (v) => _accountId = v ?? '',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  widget.onSubmit(
                    Expense(
                      id: widget.initial?.id,
                      date: _date,
                      createdAt: widget.initial?.createdAt ?? DateTime.now(),
                      description: _description,
                      value: _value,
                      installments: _installments,
                      place: _place,
                      categoryId: _categoryId,
                      accountId: _accountId,
                    ),
                  );
                }
              },
              child: Text(widget.initial == null
                  ? 'add_expense'.tr()
                  : 'save_changes'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
