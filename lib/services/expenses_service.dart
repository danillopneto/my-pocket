import '../models/expense.dart';
import 'firestore_service.dart';
import 'package:flutter/material.dart';
import '../widgets/undo_delete_helper.dart';
import '../utils/firebase_user_utils.dart';

class ExpensesService {
  final FirestoreService firestoreService;

  ExpensesService({required this.firestoreService});
  Future<void> updateExpense(
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

  Future<void> deleteExpenseWithUndo({
    required BuildContext context,
    required Expense expense,
    required List<String> pendingDeleteIds,
    required VoidCallback onLocalUpdate,
  }) async {
    await withCurrentUserAsync((user) async {
      if (expense.id == null) return;
      final stream = firestoreService.getExpenses(user.uid);
      final snapshot = await stream.first;
      final localExpenses = List<Expense>.from(snapshot);
      await showUndoableDelete(
        context: context,
        expense: expense,
        localExpenses: localExpenses,
        firestoreService: firestoreService,
        onLocalUpdate: onLocalUpdate,
      );
    });
  }
}
