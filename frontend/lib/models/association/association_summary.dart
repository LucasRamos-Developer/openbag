import '../delivery/delivery_rate.dart';
import 'association.dart';

/// Associação ativa como aparece em listas públicas (cadastro do entregador, parceiros do restaurante)
class AssociationSummary {
  final int id;
  final AssociationType type;
  final String tradingName;
  final String? description;
  final String? logoUrl;
  final String? city;
  final String? state;
  final DeliveryRate deliveryRate;

  AssociationSummary({
    required this.id,
    required this.type,
    required this.tradingName,
    this.description,
    this.logoUrl,
    this.city,
    this.state,
    this.deliveryRate = const DeliveryRate(),
  });

  factory AssociationSummary.fromJson(Map<String, dynamic> json) => AssociationSummary(
        id: json['id'],
        type: AssociationType.fromName(json['type']),
        tradingName: json['tradingName'] ?? '',
        description: json['description'],
        logoUrl: json['logoUrl'],
        city: json['city'],
        state: json['state'],
        deliveryRate: DeliveryRate.fromJson(json['deliveryRate']),
      );

  String? get location => city == null ? null : [city, state].whereType<String>().join(' - ');
}
