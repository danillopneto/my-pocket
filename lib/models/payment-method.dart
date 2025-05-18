// PaymentMethod model
class PaymentMethod {
  final String? id;
  final String name;

  PaymentMethod({this.id, required this.name});

  factory PaymentMethod.fromMap(Map<String, dynamic> map, {String? id}) {
    return PaymentMethod(
      id: id,
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
