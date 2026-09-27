class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserType userType;
  final bool isActive;
  final List<String> roles;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.isActive,
    this.roles = const [],
  });

  bool hasRole(String role) => roles.contains(role);

  bool get isAdmin => hasRole(UserRoles.admin);
  bool get isAssociationManager => hasRole(UserRoles.associationManager);
  bool get isRestaurantOwner => hasRole(UserRoles.restaurantOwner);
  bool get isDeliveryPerson => hasRole(UserRoles.deliveryPerson);

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.CUSTOMER,
      ),
      isActive: json['isActive'] ?? json['active'] ?? true,
      roles: List<String>.from(json['roleNames'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.name,
      'isActive': isActive,
      'roleNames': roles,
    };
  }
}

enum UserType {
  CUSTOMER,
  RESTAURANT_OWNER,
  DELIVERY_PERSON,
  ADMIN,
  ORGANIZATION,
}

/// Nomes das roles do backend
class UserRoles {
  static const admin = 'ADMIN';
  static const customer = 'CUSTOMER';
  static const restaurantOwner = 'RESTAURANT_OWNER';
  static const deliveryPerson = 'DELIVERY_PERSON';
  static const associationManager = 'ASSOCIATION_MANAGER';
}
