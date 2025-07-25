import '../models/expense.dart';
import 'firestore_service.dart';
import 'package:flutter/material.dart';
import '../widgets/undo_delete_helper.dart';
import '../utils/firebase_user_utils.dart';

class ExpensesService {
  final FirestoreService firestoreService;

  ExpensesService({required this.firestoreService});
  Future<void> upsertExpense(
      BuildContext context, Expense oldExpense, Expense edited) async {
    await withCurrentUserAsync((user) async {
      final updated = Expense(
        id: oldExpense.id,
        date: edited.date,
        createdAt: oldExpense.createdAt,
        description: edited.description,
        value: edited.value,
        installments: edited.installments,
        place: edited.place,
        categoryId: edited.categoryId,
        paymentMethodId: edited.paymentMethodId,
        receiptImageUrl: edited.receiptImageUrl,
        itemNames: edited.itemNames, // Preserve itemNames from edited expense
      );

      // Check if this is a new expense (id is null) or existing expense
      if (oldExpense.id == null) {
        // New expense - use addExpense
        await firestoreService.addExpense(user.uid, updated);
      } else {
        // Existing expense - use updateExpense
        await firestoreService.updateExpense(user.uid, updated);
      }
    });
  }

  Future<bool> deleteExpenseWithUndo(
      {required BuildContext context, required Expense expense}) async {
    return await showConfirmDeleteWithUndo(
      context: context,
      expense: expense,
      firestoreService: firestoreService,
    );
  }
}
