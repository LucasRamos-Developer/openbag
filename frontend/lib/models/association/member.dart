import 'association.dart';
import '../courier/vehicle.dart';
import '../courier/vehicle_type.dart';

export '../courier/vehicle_type.dart';

/// Associado: vínculo do entregador com a associação
class Member {
  final int membershipId;
  final MembershipStatus status;
  final MembershipOrigin origin;
  final int? memberNumber;
  final DateTime? requestedAt;
  final DateTime? decidedAt;
  final DateTime? endedAt;
  final String? reason;
  final int deliveryPersonId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final String documentNumber;
  final String? driverLicense;
  final VehicleType vehicleType;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final bool available;
  final double rating;
  final int totalDeliveries;

  /// Faturas da mensalidade em aberto (quantidade e total)
  final int openInvoices;
  final double openAmount;

  /// Veículos cadastrados: só vêm na ficha do associado (vazio na listagem)
  final List<Vehicle> vehicles;

  Member({
    required this.membershipId,
    required this.status,
    required this.origin,
    this.memberNumber,
    this.requestedAt,
    this.decidedAt,
    this.endedAt,
    this.reason,
    required this.deliveryPersonId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.documentNumber,
    this.driverLicense,
    required this.vehicleType,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    required this.available,
    required this.rating,
    required this.totalDeliveries,
    this.vehicles = const [],
    this.openInvoices = 0,
    this.openAmount = 0,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      membershipId: json['membershipId'],
      status: MembershipStatus.fromName(json['status']),
      origin: MembershipOrigin.fromName(json['origin']),
      memberNumber: json['memberNumber'],
      requestedAt: parseDate(json['requestedAt']),
      decidedAt: parseDate(json['decidedAt']),
      endedAt: parseDate(json['endedAt']),
      reason: json['reason'],
      deliveryPersonId: json['deliveryPersonId'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      documentNumber: json['documentNumber'] ?? '',
      driverLicense: json['driverLicense'],
      vehicleType: VehicleType.fromName(json['vehicleType']),
      vehiclePlate: json['vehiclePlate'],
      vehicleModel: json['vehicleModel'],
      vehicleColor: json['vehicleColor'],
      available: json['available'] ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      vehicles: (json['vehicles'] as List? ?? const []).map((v) => Vehicle.fromJson(v)).toList(),
      openInvoices: json['openInvoices'] ?? 0,
      openAmount: (json['openAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// CPF formatado: 529.982.247-25
  String get formattedDocument {
    final d = documentNumber;
    if (d.length != 11) return d;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  String get vehicleSummary {
    final parts = [vehicleType.label, vehicleModel, vehicleColor, vehiclePlate]
        .where((p) => p != null && p.isNotEmpty);
    return parts.join(' · ');
  }
}

enum MembershipStatus {
  PENDING('Pendente'),
  ACTIVE('Ativo'),
  SUSPENDED('Suspenso'),
  REJECTED('Recusado'),
  LEFT('Saiu'),
  REMOVED('Desligado');

  final String label;
  const MembershipStatus(this.label);

  static MembershipStatus fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => PENDING);
}

enum MembershipOrigin {
  SELF_REQUEST('Solicitação do entregador'),
  MANAGER_CREATED('Cadastrado pelo gestor'),
  INVITE('Código de convite');

  final String label;
  const MembershipOrigin(this.label);

  static MembershipOrigin fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => SELF_REQUEST);
}

/// Página de resultados do Spring Data
class MemberPage {
  final List<Member> items;
  final int page;
  final int totalPages;
  final int totalElements;

  MemberPage({required this.items, required this.page, required this.totalPages, required this.totalElements});

  bool get hasMore => page + 1 < totalPages;

  factory MemberPage.fromJson(Map<String, dynamic> json) {
    return MemberPage(
      items: (json['content'] as List).map((e) => Member.fromJson(e)).toList(),
      page: json['number'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
    );
  }
}

/// Filtro da lista de associados pela mensalidade
enum MemberBillingFilter {
  OPEN('Em aberto'),
  UP_TO_DATE('Em dia');

  final String label;
  const MemberBillingFilter(this.label);
}
