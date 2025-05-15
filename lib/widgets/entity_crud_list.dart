import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'entity_form.dart';

class EntityCrudList<T> extends StatefulWidget {
  final List<T> entities;
  final String labelText;
  final String Function(T) getName;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(T entity, String name) onEdit;
  final Future<void> Function(T entity) onDelete;
  final String emptyText;
  final String addLabel;
  final String saveLabel;
  final String entityName;

  const EntityCrudList({
    super.key,
    required this.entities,
    required this.labelText,
    required this.getName,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.emptyText,
    required this.addLabel,
    required this.saveLabel,
    required this.entityName,
  });

  @override
  State<EntityCrudList<T>> createState() => _EntityCrudListState<T>();
}

class _EntityCrudListState<T> extends State<EntityCrudList<T>> {
  final TextEditingController _controller = TextEditingController();
  String _name = '';
  T? _editing;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _edit(T entity) {
    setState(() {
      _editing = entity;
      _name = widget.getName(entity);
      _controller.text = _name;
    });
  }

  void _cancel() {
    setState(() {
      _editing = null;
      _name = '';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<T>.from(widget.entities)
      ..sort((a, b) => widget
          .getName(a)
          .toLowerCase()
          .compareTo(widget.getName(b).toLowerCase()));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: EntityForm(
            fields: [
              FormFieldConfig(
                name: 'name',
                label: widget.labelText.tr(),
                controller: _controller,
                validator: (v) =>
                    v == null || v.isEmpty ? 'required'.tr() : null,
                initialValue: _name,
              ),
            ],
            submitLabel:
                _editing == null ? widget.addLabel.tr() : widget.saveLabel.tr(),
            onCancel: _editing != null ? _cancel : null,
            onSubmit: (values) async {
              _name = values['name'] ?? '';
              if (_editing == null) {
                await widget.onAdd(_name);
              } else {
                await widget.onEdit(_editing as T, _name);
              }
              setState(() {
                _editing = null;
                _name = '';
                _controller.clear();
              });
            },
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? Center(child: Text(widget.emptyText.tr()))
              : ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final entity = sorted[i];
                    return ListTile(
                      title: Text(widget.getName(entity)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _edit(entity),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => widget.onDelete(entity),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
