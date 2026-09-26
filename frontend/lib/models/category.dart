/// Categoria global (tipo de cozinha do restaurante ou categoria de produto)
class Category {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['iconUrl'],
    );
  }
}
