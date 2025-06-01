import 'package:cloud_firestore/cloud_firestore.dart';

// Expense model
class Expense {
  final String? id;
  final DateTime date;
  final DateTime createdAt;
  final String description;
  final double value;
  final int installments;
  final String place;
  final String categoryId;
  final String paymentMethodId;
  final String? receiptImageUrl; // URL of the uploaded receipt image
  final List<String>? itemNames; // List of item names for search functionality

  Expense({
    this.id,
    required this.date,
    required this.createdAt,
    required this.description,
    required this.value,
    required this.installments,
    required this.place,
    required this.categoryId,
    required this.paymentMethodId,
    this.receiptImageUrl,
    this.itemNames,
  });

  factory Expense.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return Expense(
      id: id,
      date: parseDate(map['date']),
      createdAt: parseDate(map['createdAt']),
      description: map['description'] ?? '',
      value: (map['value'] is int)
          ? (map['value'] as int).toDouble()
          : (map['value'] as num?)?.toDouble() ?? 0.0,
      installments: map['installments'] ?? 1,
      place: map['place'] ?? '',
      categoryId: map['categoryId'] ?? '',
      paymentMethodId: map['paymentMethodId'] ?? '',
      receiptImageUrl: map['receiptImageUrl'],
      itemNames: map['itemNames'] != null
          ? List<String>.from(map['itemNames'] as List)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'value': value,
      'installments': installments,
      'place': place,
      'categoryId': categoryId,
      'paymentMethodId': paymentMethodId,
      'receiptImageUrl': receiptImageUrl,
      'itemNames': itemNames,
    };
  }
}
