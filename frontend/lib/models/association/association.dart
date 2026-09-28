import '../delivery/delivery_rate.dart';

/// Associação/cooperativa de entregadores
class Association {
  final int id;
  final AssociationType type;
  final AssociationStatus status;
  final String companyName;
  final String tradingName;
  final String cnpj;
  final String? description;
  final String? phoneNumber;
  final String? contactEmail;
  final String? logoUrl;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final AssociationAddress? address;
  final AssociationManager? manager;
  final DeliveryRate deliveryRate;

  /// A cobrança da mensalidade dos cooperados já foi definida
  final bool feePolicyConfigured;

  Association({
    required this.id,
    required this.type,
    required this.status,
    required this.companyName,
    required this.tradingName,
    required this.cnpj,
    this.description,
    this.phoneNumber,
    this.contactEmail,
    this.logoUrl,
    this.rejectionReason,
    this.approvedAt,
    this.createdAt,
    this.address,
    this.manager,
    this.deliveryRate = const DeliveryRate(),
    this.feePolicyConfigured = false,
  });

  bool get isActive => status == AssociationStatus.ACTIVE;

  /// CNPJ com máscara (XX.XXX.XXX/XXXX-XX); o backend guarda sem pontuação
  String get formattedCnpj {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/'
        '${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
  }

  factory Association.fromJson(Map<String, dynamic> json) {
    return Association(
      id: json['id'],
      type: AssociationType.fromName(json['type']),
      status: AssociationStatus.fromName(json['status']),
      companyName: json['companyName'] ?? '',
      tradingName: json['tradingName'] ?? '',
      cnpj: json['cnpj'] ?? '',
      description: json['description'],
      phoneNumber: json['phoneNumber'],
      contactEmail: json['contactEmail'],
      logoUrl: json['logoUrl'],
      rejectionReason: json['rejectionReason'],
      approvedAt: parseDate(json['approvedAt']),
      createdAt: parseDate(json['createdAt']),
      address: json['address'] != null ? AssociationAddress.fromJson(json['address']) : null,
      manager: json['manager'] != null ? AssociationManager.fromJson(json['manager']) : null,
      deliveryRate: DeliveryRate.fromJson(json['deliveryRate']),
      feePolicyConfigured: json['feePolicyConfigured'] ?? false,
    );
  }
}

class AssociationAddress {
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  AssociationAddress({
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

  factory AssociationAddress.fromJson(Map<String, dynamic> json) {
    return AssociationAddress(
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

  String get summary => '$street, $number - $neighborhood, $city/$state';
}

class AssociationManager {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;

  AssociationManager({required this.id, required this.fullName, required this.email, this.phoneNumber});

  factory AssociationManager.fromJson(Map<String, dynamic> json) {
    return AssociationManager(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }
}

enum AssociationType {
  ASSOCIATION('Associação'),
  COOPERATIVE('Cooperativa');

  final String label;
  const AssociationType(this.label);

  static AssociationType fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => ASSOCIATION);
}

enum AssociationStatus {
  PENDING_APPROVAL('Aguardando aprovação'),
  ACTIVE('Ativa'),
  REJECTED('Recusada'),
  SUSPENDED('Suspensa');

  final String label;
  const AssociationStatus(this.label);

  static AssociationStatus fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => PENDING_APPROVAL);
}

DateTime? parseDate(dynamic value) => value is String ? DateTime.tryParse(value) : null;
