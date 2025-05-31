// Model for individual expense items extracted from receipts
class ExpenseItem {
  final String name;
  final double value;

  ExpenseItem({
    required this.name,
    required this.value,
  });
  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    // Parse numeric value which may be num or string
    double parsedValue;
    final rawValue = json['value'];
    if (rawValue is num) {
      parsedValue = rawValue.toDouble();
    } else if (rawValue is String) {
      parsedValue = double.tryParse(rawValue.replaceAll(',', '.')) ?? 0.0;
    } else {
      parsedValue = 0.0;
    }

    return ExpenseItem(
      name: json['name'] ?? '',
      value: parsedValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}
