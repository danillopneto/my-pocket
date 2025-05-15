// Category model
class Category {
  final String? id;
  final String name;

  Category({this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map, {String? id}) {
    return Category(
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
