// Widget for adding/editing a single expense
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../services/date_format_service.dart';
import '../services/extract_expenses_data_service.dart';

class ExpenseForm extends StatefulWidget {
  final void Function(Expense expense) onSubmit;
  final Expense? initial;
  final List<Category> categories;
  final List<PaymentMethod> paymentMethods;
  const ExpenseForm({
    required this.onSubmit,
    this.initial,
    this.categories = const <Category>[],
    this.paymentMethods = const <PaymentMethod>[],
    super.key,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  // controllers for sync with AI updates
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late TextEditingController _placeController;
  bool _aiLoading = false;
  String? _aiError;
  late DateTime _date;
  late String _description;
  late double _value;
  late int _installments;
  late String _place;
  late String _categoryId;
  late String _paymentMethodId;
  Uint8List? _previewBytes;
  final ExtractExpensesDataService _extractService =
      ExtractExpensesDataService();

  Future<void> _pickFileAndAnalyze() async {
    setState(() {
      _aiError = null;
      _aiLoading = true;
    });
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } catch (e) {
      setState(() {
        _aiError = 'receipt_upload_error'.tr();
        _aiLoading = false;
      });
      return;
    }
    if (result == null || (!kIsWeb && result.files.single.path == null)) {
      setState(() {
        _aiError = 'receipt_upload_error'.tr();
        _aiLoading = false;
      });
      return;
    }
    // Set preview image bytes for UI
    final bytes = kIsWeb
        ? result.files.single.bytes
        : await File(result.files.single.path!).readAsBytes();
    setState(() {
      _previewBytes = bytes;
    });
    try {
      final extracted = kIsWeb
          ? await _extractService.extractFromBytes(
              bytes: result.files.single.bytes!,
              categories: widget.categories,
            )
          : await _extractService.extractFromFile(
              file: File(result.files.single.path!),
              categories: widget.categories,
            );
      setState(() {
        // Update controllers so UI fields reflect AI-extracted values
        _descriptionController.text = extracted.description;
        _valueController.text = extracted.value.toString();
        _placeController.text = extracted.place;
        _date = extracted.date;
        _categoryId = widget.categories
                .firstWhere((c) => c.name == extracted.category,
                    orElse: () => widget.categories.first)
                .id ??
            '';
      });
    } catch (e) {
      setState(() {
        _aiError = '$e\n${'gemini_error'.tr()}';
      });
    }
    setState(() {
      _aiLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _date = i?.date ?? DateTime.now();
    _description = i?.description ?? '';
    _value = i?.value ?? 0.0;
    _place = i?.place ?? '';
    _descriptionController = TextEditingController(text: _description);
    _valueController =
        TextEditingController(text: _value == 0.0 ? '' : _value.toString());
    _placeController = TextEditingController(text: _place);
    _installments = i?.installments ?? 1;
    _categoryId = i?.categoryId ?? '';
    _paymentMethodId = i?.paymentMethodId ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExpenseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the categories/paymentMethods list changes and the current value is not present, reset to first available
    if (widget.categories.isNotEmpty &&
        !widget.categories.any((c) => c.id == _categoryId)) {
      setState(() => _categoryId = widget.categories.first.id ?? '');
    }
    if (widget.paymentMethods.isNotEmpty &&
        !widget.paymentMethods.any((a) => a.id == _paymentMethodId)) {
      setState(() => _paymentMethodId = widget.paymentMethods.first.id ?? '');
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
            // Upload component
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text('upload_receipt'.tr()),
                    onPressed: _aiLoading ? null : _pickFileAndAnalyze,
                  ),
                ),
                if (_aiLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
            if (_aiError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_aiError!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_previewBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.memory(_previewBytes!,
                    height: 200, fit: BoxFit.contain),
              ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'description'.tr()),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
            ),
            TextFormField(
              controller: _valueController,
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
              controller: _placeController,
              decoration: InputDecoration(labelText: 'place'.tr()),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
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
              value: widget.paymentMethods.any((a) => a.id == _paymentMethodId)
                  ? _paymentMethodId
                  : null,
              decoration: InputDecoration(labelText: 'payment_method'.tr()),
              items: widget.paymentMethods
                  .map((acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethodId = v ?? ''),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
              onSaved: (v) => _paymentMethodId = v ?? '',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final desc = _descriptionController.text;
                  final val = double.tryParse(
                          _valueController.text.replaceAll(',', '.')) ??
                      0.0;
                  final plc = _placeController.text;
                  widget.onSubmit(
                    Expense(
                      id: widget.initial?.id,
                      date: _date,
                      createdAt: widget.initial?.createdAt ?? DateTime.now(),
                      description: desc,
                      value: val,
                      installments: _installments,
                      place: plc,
                      categoryId: _categoryId,
                      paymentMethodId: _paymentMethodId,
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
