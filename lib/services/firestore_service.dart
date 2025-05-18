import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment-method.dart';

// Handles CRUD operations for expenses, categories, paymentMethods
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Expenses
  Future<void> addExpense(String userId, Expense expense) async {
    await _db.collection('users').doc(userId).collection('expenses').add({
      ...expense.toMap(),
      'date': Timestamp.fromDate(expense.date),
      'createdAt': Timestamp.fromDate(expense.createdAt),
    });
  }

  Future<void> addExpenses(String userId, List<Expense> expenses) async {
    final batch = _db.batch();
    final expensesRef =
        _db.collection('users').doc(userId).collection('expenses');
    for (final expense in expenses) {
      final docRef = expensesRef.doc();
      batch.set(docRef, {
        ...expense.toMap(),
        'date': Timestamp.fromDate(expense.date),
        'createdAt': Timestamp.fromDate(expense.createdAt),
      });
    }
    await batch.commit();
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    if (expense.id == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expense.id)
        .update({
      ...expense.toMap(),
      'date': Timestamp.fromDate(expense.date),
      'createdAt': Timestamp.fromDate(expense.createdAt),
    });
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Stream<List<Expense>> getExpenses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  // Categories
  Future<void> addCategory(String userId, Category category) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toMap());
  }

  Future<void> updateCategory(String userId, Category category) async {
    if (category.id == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  Stream<List<Category>> getCategories(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  // Payment Methods
  Future<void> addPaymentMethod(
      String userId, PaymentMethod paymentMethod) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .add(paymentMethod.toMap());
  }

  Future<void> updatePaymentMethod(
      String userId, PaymentMethod paymentMethod) async {
    if (paymentMethod.id == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .doc(paymentMethod.id)
        .update(paymentMethod.toMap());
  }

  Future<void> deletePaymentMethod(
      String userId, String paymentMethodId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .doc(paymentMethodId)
        .delete();
  }

  Stream<List<PaymentMethod>> getPaymentMethods(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethod.fromMap(doc.data(), id: doc.id))
            .toList());
  }
}
