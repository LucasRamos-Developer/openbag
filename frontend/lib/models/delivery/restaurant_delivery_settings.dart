import '../association/association.dart' show parseDate;
import 'delivery_rate.dart';

/// Quais entregadores recebem os pedidos do restaurante
enum CourierPolicy {
  OPEN('Qualquer entregador', 'Todos os entregadores online por perto, de qualquer associação.'),
  PARTNERS_ONLY('Só associações parceiras', 'Apenas entregadores das associações que você escolher.'),
  FIXED_ONLY('Só entregadores fixos', 'Apenas os seus entregadores fixos que fizeram check-in na loja.');

  final String label;
  final String description;
  const CourierPolicy(this.label, this.description);

  static CourierPolicy fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OPEN);
}

/// Associação parceira do restaurante
class Partner {
  final int organizationId;
  final String name;
  final String? logoUrl;
  final String? city;
  final String? state;
  final DeliveryRate deliveryRate;
  final DateTime? since;
  final bool exceedsDeliveryFee;

  Partner({
    required this.organizationId,
    required this.name,
    this.logoUrl,
    this.city,
    this.state,
    required this.deliveryRate,
    this.since,
    required this.exceedsDeliveryFee,
  });

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
        organizationId: json['organizationId'],
        name: json['name'] ?? '',
        logoUrl: json['logoUrl'],
        city: json['city'],
        state: json['state'],
        deliveryRate: DeliveryRate.fromJson(json['deliveryRate']),
        since: parseDate(json['since']),
        exceedsDeliveryFee: json['exceedsDeliveryFee'] ?? false,
      );
}

/// Regras de entrega do restaurante
class RestaurantDeliverySettings {
  final CourierPolicy courierPolicy;
  final bool fallbackToOpen;
  final bool coversDeliveryDifference;
  final DateTime? coversDeliveryDifferenceAcceptedAt;
  final double deliveryFee;
  final List<Partner> partners;
  final int activeFixedCouriers;
  final int pendingFixedCouriers;

  RestaurantDeliverySettings({
    required this.courierPolicy,
    required this.fallbackToOpen,
    required this.coversDeliveryDifference,
    this.coversDeliveryDifferenceAcceptedAt,
    required this.deliveryFee,
    required this.partners,
    required this.activeFixedCouriers,
    required this.pendingFixedCouriers,
  });

  factory RestaurantDeliverySettings.fromJson(Map<String, dynamic> json) => RestaurantDeliverySettings(
        courierPolicy: CourierPolicy.fromName(json['courierPolicy']),
        fallbackToOpen: json['fallbackToOpen'] ?? false,
        coversDeliveryDifference: json['coversDeliveryDifference'] ?? false,
        coversDeliveryDifferenceAcceptedAt: parseDate(json['coversDeliveryDifferenceAcceptedAt']),
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        partners: [for (final p in (json['partners'] as List? ?? [])) Partner.fromJson(p)],
        activeFixedCouriers: json['activeFixedCouriers'] ?? 0,
        pendingFixedCouriers: json['pendingFixedCouriers'] ?? 0,
      );
}
