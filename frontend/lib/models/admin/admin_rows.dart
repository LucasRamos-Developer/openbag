import '../order/order.dart';
import '../user.dart';

/// Números da plataforma (visão geral do super admin)
class AdminOverview {
  final int restaurants;
  final int restaurantsOpenNow;
  final int associations;
  final int associationsPending;
  final int couriers;
  final int couriersOnline;
  final int users;
  final int ordersToday;

  const AdminOverview({
    required this.restaurants,
    required this.restaurantsOpenNow,
    required this.associations,
    required this.associationsPending,
    required this.couriers,
    required this.couriersOnline,
    required this.users,
    required this.ordersToday,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
        restaurants: json['restaurants'] ?? 0,
        restaurantsOpenNow: json['restaurantsOpenNow'] ?? 0,
        associations: json['associations'] ?? 0,
        associationsPending: json['associationsPending'] ?? 0,
        couriers: json['couriers'] ?? 0,
        couriersOnline: json['couriersOnline'] ?? 0,
        users: json['users'] ?? 0,
        ordersToday: json['ordersToday'] ?? 0,
      );
}

DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value) : null;

class AdminRestaurantRow {
  final int id;
  final String name;
  final String slug;
  final String? ownerName;
  final String? ownerEmail;
  final String? city;
  final bool active;
  final bool openNow;
  final DateTime? createdAt;

  const AdminRestaurantRow({
    required this.id,
    required this.name,
    required this.slug,
    this.ownerName,
    this.ownerEmail,
    this.city,
    required this.active,
    required this.openNow,
    this.createdAt,
  });

  factory AdminRestaurantRow.fromJson(Map<String, dynamic> json) => AdminRestaurantRow(
        id: json['id'],
        name: json['name'] ?? '',
        slug: json['slug'] ?? '${json['id']}',
        ownerName: json['ownerName'],
        ownerEmail: json['ownerEmail'],
        city: json['city'],
        active: json['active'] ?? false,
        openNow: json['openNow'] ?? false,
        createdAt: _date(json['createdAt']),
      );
}

class AdminCourierRow {
  final int id;
  final String fullName;
  final String email;
  final String? slug;
  final String? association;
  final String? vehicle;
  final String workStatus;
  final bool active;
  final int totalDeliveries;
  final double rating;

  const AdminCourierRow({
    required this.id,
    required this.fullName,
    required this.email,
    this.slug,
    this.association,
    this.vehicle,
    required this.workStatus,
    required this.active,
    required this.totalDeliveries,
    required this.rating,
  });

  bool get online => workStatus == 'ONLINE' || workStatus == 'BUSY';

  String get workStatusLabel => switch (workStatus) { 'ONLINE' => 'Online', 'BUSY' => 'Em entrega', _ => 'Offline' };

  factory AdminCourierRow.fromJson(Map<String, dynamic> json) => AdminCourierRow(
        id: json['id'],
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        slug: json['slug'],
        association: json['association'],
        vehicle: json['vehicle'],
        workStatus: json['workStatus'] ?? 'OFFLINE',
        active: json['active'] ?? false,
        totalDeliveries: json['totalDeliveries'] ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
      );
}

class AdminUserRow {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final List<String> roles;
  final bool active;
  final DateTime? createdAt;

  const AdminUserRow({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.roles,
    required this.active,
    this.createdAt,
  });

  /// Nomes dos papéis em português
  static String roleLabel(String role) => switch (role) {
        UserRoles.admin => 'Admin',
        UserRoles.customer => 'Cliente',
        UserRoles.restaurantOwner => 'Restaurante',
        UserRoles.deliveryPerson => 'Entregador',
        UserRoles.associationManager => 'Cooperativa',
        _ => role,
      };

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => AdminUserRow(
        id: json['id'],
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phoneNumber'],
        roles: List<String>.from(json['roles'] ?? const []),
        active: json['active'] ?? false,
        createdAt: _date(json['createdAt']),
      );
}

class AdminOrderRow {
  final int id;
  final String displayCode;
  final String restaurantName;
  final String? restaurantSlug;
  final String? customerName;
  final String? courierName;
  final OrderStatus status;
  final double totalAmount;
  final DateTime? createdAt;

  const AdminOrderRow({
    required this.id,
    required this.displayCode,
    required this.restaurantName,
    this.restaurantSlug,
    this.customerName,
    this.courierName,
    required this.status,
    required this.totalAmount,
    this.createdAt,
  });

  factory AdminOrderRow.fromJson(Map<String, dynamic> json) => AdminOrderRow(
        id: json['id'],
        displayCode: json['displayCode'] ?? '#${json['id']}',
        restaurantName: json['restaurantName'] ?? '',
        restaurantSlug: json['restaurantSlug'],
        customerName: json['customerName'],
        courierName: json['courierName'],
        status: OrderStatus.fromName(json['status']),
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        createdAt: _date(json['createdAt']),
      );
}
