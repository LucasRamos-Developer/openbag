import '../courier/vehicle_type.dart';
import '../order/order.dart';

/// Quem pode levar um pedido agora e se a loja pode trocar quem está com ele
class CourierOptions {
  final CurrentCourier? current;
  final List<CourierOption> options;

  CourierOptions({this.current, required this.options});

  factory CourierOptions.fromJson(Map<String, dynamic> json) => CourierOptions(
        current: json['current'] != null ? CurrentCourier.fromJson(json['current']) : null,
        options: [for (final o in json['options'] as List? ?? []) CourierOption.fromJson(o)],
      );
}

/// Quem está com o pedido e a regra de troca: fixo e equipe a qualquer momento; livre só se não aparecer
class CurrentCourier {
  final CourierKind? kind;
  final String? name;
  final bool canReassign;
  final String? reason;
  final DateTime? availableAt;
  final bool atStore;

  CurrentCourier({this.kind, this.name, required this.canReassign, this.reason, this.availableAt, this.atStore = false});

  factory CurrentCourier.fromJson(Map<String, dynamic> json) => CurrentCourier(
        kind: CourierKind.fromName(json['kind']),
        name: json['name'],
        canReassign: json['canReassign'] ?? false,
        reason: json['reason'],
        availableAt: json['availableAt'] != null ? DateTime.tryParse(json['availableAt']) : null,
        atStore: json['atStore'] ?? false,
      );
}

/// Entregador que pode receber o pedido (do app ou da equipe)
class CourierOption {
  final CourierKind kind;
  final int? deliveryPersonId;
  final int? staffCourierId;
  final String name;
  final String? photoUrl;
  final VehicleType? vehicleType;
  final double? distanceKm;
  final double? fee;

  /// Motivo de não poder receber agora; nulo = pode
  final String? blockedReason;

  CourierOption({
    required this.kind,
    this.deliveryPersonId,
    this.staffCourierId,
    required this.name,
    this.photoUrl,
    this.vehicleType,
    this.distanceKm,
    this.fee,
    this.blockedReason,
  });

  bool get available => blockedReason == null;

  factory CourierOption.fromJson(Map<String, dynamic> json) => CourierOption(
        kind: CourierKind.fromName(json['kind']) ?? CourierKind.FREE,
        deliveryPersonId: json['deliveryPersonId'],
        staffCourierId: json['staffCourierId'],
        name: json['name'] ?? '',
        photoUrl: json['photoUrl'],
        vehicleType: json['vehicleType'] != null ? VehicleType.fromName(json['vehicleType']) : null,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        fee: (json['fee'] as num?)?.toDouble(),
        blockedReason: json['blockedReason'],
      );
}
