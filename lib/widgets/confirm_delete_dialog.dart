import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ConfirmDeleteDialog extends StatefulWidget {
  final String? title;
  final String? content;
  final Future<bool> Function()? onDelete;

  const ConfirmDeleteDialog(
      {super.key, this.title, this.content, this.onDelete});

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool _isDeleting = false;
  bool _showCountdown = false;
  int _countdownSeconds = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? 'confirm_delete'.tr()),
      content: Text(widget.content ?? 'delete_expense_confirm'.tr()),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    if (_isDeleting) {
      return [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('deleting_expense'.tr()),
          ],
        ),
      ];
    }

    if (_showCountdown) {
      return [
        TextButton(
          onPressed: _undo,
          child: Text(
              'undo_with_countdown'.tr(args: [_countdownSeconds.toString()])),
        ),
        TextButton(
          onPressed: _deleteRightAway,
          child: Text('delete_right_away'.tr()),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text('cancel'.tr()),
      ),
      TextButton(
        onPressed: _startCountdown,
        child: Text('delete'.tr()),
      ),
    ];
  }

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownSeconds = 5;
    });

    _countdown();
  }

  void _countdown() {
    if (_countdownSeconds > 0 && _showCountdown) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _showCountdown) {
          setState(() {
            _countdownSeconds--;
          });
          if (_countdownSeconds > 0) {
            _countdown();
          } else {
            _deleteRightAway();
          }
        }
      });
    }
  }

  void _undo() {
    setState(() {
      _showCountdown = false;
      _countdownSeconds = 5;
    });
  }

  void _deleteRightAway() async {
    setState(() {
      _isDeleting = true;
      _showCountdown = false;
    });

    try {
      bool success = false;
      if (widget.onDelete != null) {
        success = await widget.onDelete!();
      }

      if (mounted) {
        Navigator.of(context).pop(success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        // Show error but don't close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_expense_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
