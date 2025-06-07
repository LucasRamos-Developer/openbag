class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? promotionalPrice;
  final String? imageUrl;
  final bool isAvailable;
  final int? preparationTime;
  final int restaurantId;
  final Category? category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.promotionalPrice,
    this.imageUrl,
    required this.isAvailable,
    this.preparationTime,
    required this.restaurantId,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      promotionalPrice: json['promotionalPrice']?.toDouble(),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      preparationTime: json['preparationTime'],
      restaurantId: json['restaurantId'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }

  double get currentPrice => promotionalPrice ?? price;
  bool get hasPromotion => promotionalPrice != null && promotionalPrice! < price;
  String get formattedPrice => 'R\$ ${currentPrice.toStringAsFixed(2).replaceAll('.', ',')}';
  String get formattedOriginalPrice => 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
}

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
