import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
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
    int? limit,
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
    if (limit != null) {
      query = query.limit(limit);
    }
    return logFirestoreStreamErrors(
      query
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList()),
      context: 'getExpenses',
    );
  }

  // Search expenses by item names
  Stream<List<Expense>> searchExpensesByItemName(
    String userId,
    String itemName, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    // Convert search term to lowercase for case-insensitive search
    final searchTerm = itemName.toLowerCase().trim();

    var query = _db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('itemNames', arrayContains: searchTerm)
        .orderBy('date', descending: true)
        .withConverter<Expense>(
          fromFirestore: (snap, _) =>
              Expense.fromMap(snap.data()!, id: snap.id),
          toFirestore: (exp, _) => exp.toMap(),
        );

    if (limit != null) {
      query = query.limit(limit);
    }

    return logFirestoreStreamErrors(
      query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).where((expense) {
                // Additional filtering by date if needed (since we can't combine array-contains with date range easily)
                if (startDate != null && expense.date.isBefore(startDate)) {
                  return false;
                }
                if (endDate != null && expense.date.isAfter(endDate)) {
                  return false;
                }
                return true;
              }).toList()),
      context: 'searchExpensesByItemName',
    );
  }

  // Get most recent expense containing a specific item
  Future<Expense?> getLastExpenseWithItem(
      String userId, String itemName) async {
    final searchTerm = itemName.toLowerCase().trim();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .where('itemNames', arrayContains: searchTerm)
          .orderBy('date', descending: true)
          .limit(1)
          .withConverter<Expense>(
            fromFirestore: (snap, _) =>
                Expense.fromMap(snap.data()!, id: snap.id),
            toFirestore: (exp, _) => exp.toMap(),
          )
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting last expense with item: $e');
      return null;
    }
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

  // Search expenses by description (partial match)
  Stream<List<Expense>> searchExpensesByDescription(
    String userId,
    String searchTerm, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    if (searchTerm.trim().isEmpty) {
      return Stream.value([]);
    }

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

    if (limit != null) {
      query = query.limit(limit * 10); // Get more results to filter locally
    }

    return logFirestoreStreamErrors(
      query.snapshots().map((snapshot) {
        final searchTermLower = searchTerm.toLowerCase().trim();
        return snapshot.docs
            .map((doc) => doc.data())
            .where((expense) {
              // Filter by date range
              if (startDate != null && expense.date.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && expense.date.isAfter(endDate)) {
                return false;
              }

              // Filter by description or place containing search term
              final description = expense.description.toLowerCase();
              final place = expense.place.toLowerCase();

              return description.contains(searchTermLower) ||
                  place.contains(searchTermLower);
            })
            .take(limit ?? 50) // Apply final limit
            .toList();
      }),
      context: 'searchExpensesByDescription',
    );
  }

  // Combined search: items, description, and place
  Stream<List<Expense>> searchExpensesAll(
    String userId,
    String searchTerm, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    if (searchTerm.trim().isEmpty) {
      return Stream.value([]);
    }

    // First try item search
    final itemSearchStream = searchExpensesByItemName(
      userId,
      searchTerm,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    // Then combine with description search
    final descSearchStream = searchExpensesByDescription(
      userId,
      searchTerm,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    // Combine both streams and remove duplicates
    return logFirestoreStreamErrors(
      itemSearchStream.asyncMap((itemResults) async {
        final descResults = await descSearchStream.first;
        final Map<String, Expense> uniqueExpenses = {};

        // Add item search results
        for (final expense in itemResults) {
          if (expense.id != null) {
            uniqueExpenses[expense.id!] = expense;
          }
        }

        // Add description search results (avoiding duplicates)
        for (final expense in descResults) {
          if (expense.id != null && !uniqueExpenses.containsKey(expense.id!)) {
            uniqueExpenses[expense.id!] = expense;
          }
        }

        // Sort by date descending and apply limit
        final results = uniqueExpenses.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return limit != null ? results.take(limit).toList() : results;
      }),
      context: 'searchExpensesAll',
    );
  }
}
