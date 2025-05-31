import 'expense_item.dart';

// Model for AI expense extraction response
class AiExpenseExtracted {
  final String description;
  final double value;
  final String place;
  final DateTime date;
  final String category;
  final List<ExpenseItem> items;

  AiExpenseExtracted({
    required this.description,
    required this.value,
    required this.place,
    required this.date,
    required this.category,
    required this.items,
  });
  factory AiExpenseExtracted.fromJson(Map<String, dynamic> json) {
    // Parse numeric value which may be num or string
    double parsedValue;
    final rawValue = json['value'];
    if (rawValue is num) {
      parsedValue = rawValue.toDouble();
    } else if (rawValue is String) {
      parsedValue = double.tryParse(rawValue.replaceAll(',', '.')) ?? 0.0;
    } else {
      parsedValue = 0.0;
    } // Parse items array
    List<ExpenseItem> parsedItems = [];
    if (json['items'] is List) {
      final itemsList = json['items'] as List;
      parsedItems =
          itemsList.map((item) => ExpenseItem.fromJson(item)).toList();
    }

    // Only calculate total from items if no total value was extracted from the receipt
    // This prioritizes the actual receipt total over calculated totals
    if (parsedValue == 0.0 && parsedItems.isNotEmpty) {
      parsedValue = parsedItems.fold(0.0, (sum, item) => sum + item.value);
    }

    return AiExpenseExtracted(
      description: json['description'] ?? '',
      value: parsedValue,
      place: json['place'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? '',
      items: parsedItems,
    );
  }
}
