import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../utils/firebase_user_utils.dart';

/// Shows a SnackBar with Undo for deleting an expense. Only deletes from Firestore if not undone.
Future<void> showUndoableDelete({
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
    content:
        Text('expense_deleted'.tr()), // Use .tr() if localization is set up
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {
        undo = true;
        localExpenses.insert(0, expense);
        onLocalUpdate();
      },
    ),
    duration: Duration(seconds: seconds),
  );
  scaffoldMessenger.showSnackBar(snackBar);

  await Future.delayed(Duration(seconds: seconds));
  if (!undo) {
    await withCurrentUserAsync((user) async {
      if (expense.id != null) {
        await firestoreService.deleteExpense(user.uid, expense.id!);
      }
    });
  }
}
