import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../services/receipt_upload_service.dart';
import '../utils/firebase_user_utils.dart';

/// Shows a SnackBar with Undo for deleting an expense. Only deletes from Firestore if not undone.
/// Returns true if the expense was actually deleted, false if undone.
Future<bool> showUndoableDelete({
  required BuildContext context,
  required Expense expense,
  required List<Expense> localExpenses,
  required FirestoreService firestoreService,
  required VoidCallback onLocalUpdate,
  int seconds = 5,
}) async {
  // Remove from local list
  localExpenses.removeWhere((e) => e.id == expense.id);
  onLocalUpdate();

  bool undo = false;
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final snackBar = SnackBar(
    content: Text('deleting_expense_undo'.tr()),
    action: SnackBarAction(
      label: 'undo'.tr(),
      onPressed: () {
        undo = true;
        localExpenses.insert(0, expense);
        onLocalUpdate();
        scaffoldMessenger.hideCurrentSnackBar();
      },
    ),
    duration: Duration(seconds: seconds),
  );
  scaffoldMessenger.showSnackBar(snackBar);
  await Future.delayed(Duration(seconds: seconds));

  if (!undo) {
    // Show loading state while actually deleting
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
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
        duration:
            const Duration(minutes: 1), // Long duration, we'll hide it manually
      ),
    );

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

      // Hide loading and show success
      scaffoldMessenger.hideCurrentSnackBar();
      return true; // Successfully deleted
    } catch (e) {
      // Hide loading and show error
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('delete_expense_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      // Restore the expense since deletion failed
      localExpenses.insert(0, expense);
      onLocalUpdate();
      return false; // Failed to delete
    }
  } else {
    return false; // Undone, not deleted
  }
}
