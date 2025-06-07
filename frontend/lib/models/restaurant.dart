class Restaurant {
  final int id;
  final String name;
  final String description;
  final String phoneNumber;
  final String? logoUrl;
  final String? bannerUrl;
  final double deliveryFee;
  final double minimumOrder;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final bool isOpen;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final Address? address;
  final List<Category> categories;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.phoneNumber,
    this.logoUrl,
    this.bannerUrl,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.isOpen,
    required this.isActive,
    required this.rating,
    required this.totalReviews,
    this.address,
    this.categories = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      phoneNumber: json['phoneNumber'],
      logoUrl: json['logoUrl'],
      bannerUrl: json['bannerUrl'],
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      minimumOrder: (json['minimumOrder'] as num).toDouble(),
      deliveryTimeMin: json['deliveryTimeMin'],
      deliveryTimeMax: json['deliveryTimeMax'],
      isOpen: json['isOpen'],
      isActive: json['isActive'],
      rating: (json['rating'] as num).toDouble(),
      totalReviews: json['totalReviews'],
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      categories: json['categories'] != null
          ? (json['categories'] as List).map((cat) => Category.fromJson(cat)).toList()
          : [],
    );
  }

  String get deliveryTimeRange => '$deliveryTimeMin-${deliveryTimeMax}min';
  String get formattedRating => rating.toStringAsFixed(1);
}

class Address {
  final int id;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      street: json['street'],
      number: json['number'],
      complement: json['complement'],
      neighborhood: json['neighborhood'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  String get fullAddress {
    final complement = this.complement?.isNotEmpty == true ? ', ${this.complement}' : '';
    return '$street, $number$complement, $neighborhood, $city - $state, $zipCode';
  }
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
