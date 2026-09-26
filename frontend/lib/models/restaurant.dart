import 'order/order.dart';
import 'store/store.dart';
export 'category.dart';

/// Restaurante na vitrine (listas e página pública)
class Restaurant {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? phoneNumber;
  final String? cnpj;
  final String? logoUrl;
  final String? bannerUrl;
  final String? primaryColor;
  final double rating;
  final int totalReviews;
  final double deliveryFee;
  final double minimumOrder;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final String? priceRange;
  final bool openNow;
  final DateTime? pausedUntil;
  final List<String> categories;
  final Address? address;
  final List<OpeningHour> openingHours;
  final List<PaymentMethod> paymentMethods;

  Restaurant({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.phoneNumber,
    this.cnpj,
    this.logoUrl,
    this.bannerUrl,
    this.primaryColor,
    required this.rating,
    required this.totalReviews,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    this.priceRange,
    required this.openNow,
    this.pausedUntil,
    this.categories = const [],
    this.address,
    this.openingHours = const [],
    this.paymentMethods = const [],
  });

  bool get isOpen => openNow;
  bool get paused => pausedUntil != null;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '${json['id']}',
      description: json['description'],
      phoneNumber: json['phoneNumber'],
      cnpj: json['cnpj'],
      logoUrl: json['logoUrl'],
      bannerUrl: json['bannerUrl'],
      primaryColor: json['primaryColor'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['totalReviews'] ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 0,
      deliveryTimeMin: json['deliveryTimeMin'] ?? 0,
      deliveryTimeMax: json['deliveryTimeMax'] ?? 0,
      priceRange: json['priceRange'],
      openNow: json['openNow'] ?? false,
      pausedUntil: json['pausedUntil'] != null ? DateTime.tryParse(json['pausedUntil']) : null,
      categories: List<String>.from(json['categories'] ?? const []),
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      openingHours: (json['openingHours'] as List? ?? []).map((e) => OpeningHour.fromJson(e)).toList(),
      paymentMethods: (json['paymentMethods'] as List? ?? []).map((e) => PaymentMethod.fromName(e)).toList(),
    );
  }

  String get deliveryTimeRange => '$deliveryTimeMin-$deliveryTimeMax min';
  String get formattedRating => rating.toStringAsFixed(1);
}

class Address {
  final int? id;
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
    this.id,
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
      street: json['street'] ?? '',
      number: json['number'] ?? '',
      complement: json['complement'],
      neighborhood: json['neighborhood'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  String get fullAddress {
    final complement = this.complement?.isNotEmpty == true ? ', ${this.complement}' : '';
    return '$street, $number$complement, $neighborhood, $city - $state, $zipCode';
  }
}
