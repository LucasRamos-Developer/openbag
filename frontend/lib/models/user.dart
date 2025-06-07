class User {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserType userType;
  final bool isActive;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['userType'],
      ),
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.toString().split('.').last,
      'isActive': isActive,
    };
  }
}

enum UserType {
  CUSTOMER,
  RESTAURANT_OWNER,
  DELIVERY_PERSON,
  ADMIN,
}
