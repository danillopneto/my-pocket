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
import '../models/expense_item.dart';
import '../services/date_format_service.dart';
import '../services/currency_format_service.dart';
import '../services/extract_expenses_data_service.dart';
import '../services/receipt_upload_service.dart';

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
  String? _receiptImageUrl; // Store the uploaded receipt URL
  Uint8List? _previewBytes;
  String? _selectedFileName; // Store the original filename
  List<ExpenseItem> _extractedItems = [];
  final ExtractExpensesDataService _extractService =
      ExtractExpensesDataService();
  Future<void> _pickFileAndAnalyze() async {
    setState(() {
      _aiError = null;
      _aiLoading = true;
      _extractedItems = []; // Clear previous items
    });
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } catch (e) {
      setState(() {
        _aiError = 'receipt_upload_error'.tr();
        _aiLoading = false;
        _extractedItems = [];
      });
      return;
    }
    if (result == null || (!kIsWeb && result.files.single.path == null)) {
      setState(() {
        _aiError = 'receipt_upload_error'.tr();
        _aiLoading = false;
        _extractedItems = [];
      });
      return;
    } // Get file bytes for preview and store for later upload
    final bytes = kIsWeb
        ? result.files.single.bytes!
        : await File(result.files.single.path!).readAsBytes();
    final fileName = result.files.single.name;

    // Set preview image bytes and filename for UI
    setState(() {
      _previewBytes = bytes;
      _selectedFileName = fileName;
    });

    try {
      // Extract data from the image using AI (no upload yet)
      final extracted = kIsWeb
          ? await _extractService.extractFromBytes(
              bytes: bytes,
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
        _extractedItems = extracted.items;
        _categoryId = widget.categories
                .firstWhere((c) => c.name == extracted.category,
                    orElse: () => widget.categories.first)
                .id ??
            '';
      });
    } catch (e) {
      setState(() {
        _aiError = '$e\n${'gemini_error'.tr()}';
        _extractedItems = []; // Clear items on error
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
    _receiptImageUrl =
        i?.receiptImageUrl; // Initialize with existing receipt URL
    _extractedItems =
        []; // Initialize empty since items are no longer stored in expense model

    // If editing an existing expense with a receipt, we don't need to store bytes
    // since the image is already uploaded and we have the URL
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
            if (_extractedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'receipt_items'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_extractedItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(item.name),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      CurrencyFormatService.formatCurrency(
                                        item.value,
                                        context,
                                      ),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                        const Divider(),
                        Row(
                          children: [
                            const Expanded(flex: 3, child: Text('')),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'items_subtotal'.tr(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Expanded(flex: 3, child: Text('')),
                            Expanded(
                              flex: 2,
                              child: Text(
                                CurrencyFormatService.formatCurrency(
                                  _extractedItems.fold(
                                      0.0, (sum, item) => sum + item.value),
                                  context,
                                ),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'receipt_total'.tr()}: ${CurrencyFormatService.formatCurrency(double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0, context)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'description'.tr()),
              validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
              onSaved: (v) => _description = v ?? '',
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
              controller: _placeController,
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
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState
                      ?.save(); // Save form state to trigger onSaved callbacks

                  String? finalReceiptImageUrl = _receiptImageUrl;

                  // Upload the receipt image if we have new image data
                  if (_previewBytes != null && _selectedFileName != null) {
                    try {
                      finalReceiptImageUrl =
                          await ReceiptUploadService.uploadReceiptImage(
                        imageBytes: _previewBytes!,
                        originalFileName: _selectedFileName!,
                      );
                    } catch (e) {
                      // Show error but don't prevent saving the expense
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('receipt_upload_error'.tr()),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                      // Use existing URL or null if upload failed
                      finalReceiptImageUrl = _receiptImageUrl;
                    }
                  }

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
                      paymentMethodId: _paymentMethodId,
                      receiptImageUrl: finalReceiptImageUrl,
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
