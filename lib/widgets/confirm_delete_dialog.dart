import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final VoidCallback? onDelete;

  const ConfirmDeleteDialog(
      {super.key, this.title, this.content, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'confirm_delete'.tr()),
      content: Text(content ?? 'delete_expense_confirm'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            onDelete?.call();
            Navigator.of(context).pop(true);
          },
          child: Text('delete'.tr()),
        ),
      ],
    );
  }
}
