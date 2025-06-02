import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../services/receipt_upload_service.dart';
import '../utils/firebase_user_utils.dart';
import 'confirm_delete_dialog.dart';

/// Shows a confirm delete dialog with built-in undo countdown functionality.
/// Returns true if the expense was actually deleted, false if cancelled.
Future<bool> showConfirmDeleteWithUndo({
  required BuildContext context,
  required Expense expense,
  required FirestoreService firestoreService,
  String? title,
  String? content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDeleteDialog(
      title: title,
      content: content,
      onDelete: () async {
        return await _performDelete(expense, firestoreService);
      },
    ),
  );

  return result ?? false;
}

/// Performs the actual expense deletion from Firestore and storage
Future<bool> _performDelete(
    Expense expense, FirestoreService firestoreService) async {
  try {
    await withCurrentUserAsync((user) async {
      if (expense.id != null) {
        // Delete the receipt image if it exists
        if (expense.receiptImageUrl != null &&
            expense.receiptImageUrl!.isNotEmpty) {
          try {
            await ReceiptUploadService.deleteReceiptImage(
                expense.receiptImageUrl!);
          } catch (e) {
            // Log error but don't fail the expense deletion
            debugPrint('Failed to delete receipt image: $e');
          }
        }

        // Delete the expense from Firestore
        await firestoreService.deleteExpense(user.uid, expense.id!);
      }
    });

    return true; // Successfully deleted
  } catch (e) {
    debugPrint('Failed to delete expense: $e');
    return false; // Failed to delete
  }
}
