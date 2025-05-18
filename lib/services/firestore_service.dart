import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment-method.dart';
import 'firestore_error_logger.dart';

// Handles CRUD operations for expenses, categories, paymentMethods
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Expenses
  Future<void> addExpense(String userId, Expense expense) async {
    await addForUser(userId, 'expenses', {
      ...expense.toMap(),
      'date': Timestamp.fromDate(expense.date),
      'createdAt': Timestamp.fromDate(expense.createdAt),
    });
  }

  Future<void> addExpenses(String userId, List<Expense> expenses) async {
    final batch = _db.batch();
    final expensesRef = _userSubcollection(userId, 'expenses');
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
    await updateForUser(userId, 'expenses', expense.id!, {
      ...expense.toMap(),
      'date': Timestamp.fromDate(expense.date),
      'createdAt': Timestamp.fromDate(expense.createdAt),
    });
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await deleteForUser(userId, 'expenses', expenseId);
  }

  Stream<List<Expense>> getExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
  }) {
    var query = _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .withConverter<Expense>(
          fromFirestore: (snap, _) =>
              Expense.fromMap(snap.data()!, id: snap.id),
          toFirestore: (exp, _) => exp.toMap(),
        );
    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query =
          query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (categoryIds != null && categoryIds.isNotEmpty) {
      // Firestore whereIn supports up to 10 values
      query = query.where('categoryId', whereIn: categoryIds.take(10).toList());
    }
    return logFirestoreStreamErrors(
      query
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList()),
      context: 'getExpenses',
    );
  }

  // Categories
  Future<void> addCategory(String userId, Category category) async {
    await addForUser(userId, 'categories', category.toMap());
  }

  Future<void> updateCategory(String userId, Category category) async {
    if (category.id == null) return;
    await updateForUser(userId, 'categories', category.id!, category.toMap());
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await deleteForUser(userId, 'categories', categoryId);
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
    await addForUser(userId, 'paymentMethods', paymentMethod.toMap());
  }

  Future<void> updatePaymentMethod(
      String userId, PaymentMethod paymentMethod) async {
    if (paymentMethod.id == null) return;
    await updateForUser(
        userId, 'paymentMethods', paymentMethod.id!, paymentMethod.toMap());
  }

  Future<void> deletePaymentMethod(
      String userId, String paymentMethodId) async {
    await deleteForUser(userId, 'paymentMethods', paymentMethodId);
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

  // Helper for user subcollections
  CollectionReference<Map<String, dynamic>> _userSubcollection(
      String userId, String sub) {
    return _db.collection('users').doc(userId).collection(sub);
  }

  Future<void> addForUser(
      String userId, String sub, Map<String, dynamic> data) async {
    await _userSubcollection(userId, sub).add(data);
  }

  Future<void> updateForUser(
      String userId, String sub, String id, Map<String, dynamic> data) async {
    await _userSubcollection(userId, sub).doc(id).update(data);
  }

  Future<void> deleteForUser(String userId, String sub, String id) async {
    await _userSubcollection(userId, sub).doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getAllForUser(
      String userId, String sub) async {
    final snap = await _userSubcollection(userId, sub).get();
    return snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }
}
