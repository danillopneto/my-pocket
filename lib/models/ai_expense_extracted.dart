// Model for AI expense extraction response
class AiExpenseExtracted {
  final String description;
  final double value;
  final String place;
  final DateTime date;
  final String category;

  AiExpenseExtracted({
    required this.description,
    required this.value,
    required this.place,
    required this.date,
    required this.category,
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
    }
    return AiExpenseExtracted(
      description: json['description'] ?? '',
      value: parsedValue,
      place: json['place'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? '',
    );
  }
}
