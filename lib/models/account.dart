// Account model
class Account {
  final String? id;
  final String name;

  Account({this.id, required this.name});

  factory Account.fromMap(Map<String, dynamic> map, {String? id}) {
    return Account(
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
