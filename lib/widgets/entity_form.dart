import 'package:flutter/material.dart';

/// A generic form widget for simple entities.
/// [fields] is a list of field definitions (label, controller, validator, onSaved, etc).
/// [onSubmit] is called with the form's current values when the form is valid and submitted.
class EntityForm extends StatefulWidget {
  final List<FormFieldConfig> fields;
  final String submitLabel;
  final VoidCallback? onCancel;
  final void Function(Map<String, dynamic> values) onSubmit;

  const EntityForm({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.onCancel,
  });

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _values[field.name] = field.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.fields.map((field) => TextFormField(
                controller: field.controller,
                decoration: InputDecoration(labelText: field.label),
                validator: field.validator,
                onSaved: (v) => _values[field.name] = v,
                keyboardType: field.keyboardType,
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    widget.onSubmit(_values);
                  }
                },
                child: Text(widget.submitLabel),
              ),
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class FormFieldConfig {
  final String name;
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? initialValue;

  FormFieldConfig({
    required this.name,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.initialValue,
  });
}
