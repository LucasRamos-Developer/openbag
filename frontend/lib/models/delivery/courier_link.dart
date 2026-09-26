import '../association/association.dart' show parseDate;
import '../courier/vehicle.dart';

enum CourierLinkStatus {
  PENDING('Pendente'),
  ACTIVE('Fixo'),
  REJECTED('Recusado'),
  ENDED('Encerrado');

  final String label;
  const CourierLinkStatus(this.label);

  static CourierLinkStatus fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => PENDING);
}

enum LinkRequester {
  COURIER,
  RESTAURANT;

  static LinkRequester fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => COURIER);
}

/// Restaurante como aparece para o entregador (vínculos, turno, entrega)
class LinkRestaurant {
  final int id;
  final String name;
  final String? slug;
  final String? logoUrl;
  final String? address;
  final double? latitude;
  final double? longitude;

  LinkRestaurant({required this.id, required this.name, this.slug, this.logoUrl, this.address, this.latitude, this.longitude});

  factory LinkRestaurant.fromJson(Map<String, dynamic> json) => LinkRestaurant(
        id: json['id'],
        name: json['name'] ?? '',
        slug: json['slug'],
        logoUrl: json['logoUrl'],
        address: json['address'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

/// Entregador como aparece para o restaurante
class LinkCourier {
  final int deliveryPersonId;
  final String fullName;
  final String? photoUrl;
  final String? slug;
  final String? phoneNumber;
  final String? associationName;
  final Vehicle? vehicle;

  LinkCourier({
    required this.deliveryPersonId,
    required this.fullName,
    this.photoUrl,
    this.slug,
    this.phoneNumber,
    this.associationName,
    this.vehicle,
  });

  factory LinkCourier.fromJson(Map<String, dynamic> json) => LinkCourier(
        deliveryPersonId: json['deliveryPersonId'],
        fullName: json['fullName'] ?? '',
        photoUrl: json['photoUrl'],
        slug: json['slug'],
        phoneNumber: json['phoneNumber'],
        associationName: json['associationName'],
        vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      );
}

/// Vínculo de entregador fixo com um restaurante
class CourierLink {
  final int id;
  final CourierLinkStatus status;
  final LinkRequester requestedBy;
  final DateTime? createdAt;
  final LinkRestaurant restaurant;
  final LinkCourier courier;
  final bool checkedIn;

  CourierLink({
    required this.id,
    required this.status,
    required this.requestedBy,
    this.createdAt,
    required this.restaurant,
    required this.courier,
    required this.checkedIn,
  });

  factory CourierLink.fromJson(Map<String, dynamic> json) => CourierLink(
        id: json['id'],
        status: CourierLinkStatus.fromName(json['status']),
        requestedBy: LinkRequester.fromName(json['requestedBy']),
        createdAt: parseDate(json['createdAt']),
        restaurant: LinkRestaurant.fromJson(json['restaurant']),
        courier: LinkCourier.fromJson(json['courier']),
        checkedIn: json['checkedIn'] ?? false,
      );

  bool get isPending => status == CourierLinkStatus.PENDING;
  bool get isActive => status == CourierLinkStatus.ACTIVE;
}
