import '../delivery/delivery_rate.dart';
import '../delivery/partnership.dart';
import 'association.dart' show parseDate;

export '../delivery/partnership.dart';

/// Parceria vista pela associação: a loja, a situação e a tabela que vale nela
class AssociationPartnership extends PartnershipInfo {
  @override
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String? slug;
  final String? logoUrl;
  final String? neighborhood;
  final String? city;
  final String? state;

  /// Taxa cobrada do cliente e se a loja assume a diferença quando a tabela passa dela
  final double deliveryFee;

  /// A loja repassa a taxa ao cliente (cobra pela maior tabela): a tabela nunca passa da taxa
  final bool passesDeliveryFee;
  final bool coversDeliveryDifference;
  @override
  final PartnershipStatus status;
  @override
  final PartnershipSide? requestedBy;
  @override
  final PartnershipSide? endedBy;
  @override
  final PartnershipSide? awaitingSide;
  @override
  final DeliveryRate? agreedRate;
  @override
  final DeliveryRate effectiveRate;
  @override
  final RateProposal? rateProposal;
  @override
  final DateTime? since;
  @override
  final DateTime? endedAt;

  AssociationPartnership({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.slug,
    this.logoUrl,
    this.neighborhood,
    this.city,
    this.state,
    required this.deliveryFee,
    this.passesDeliveryFee = false,
    required this.coversDeliveryDifference,
    required this.status,
    this.requestedBy,
    this.endedBy,
    this.awaitingSide,
    this.agreedRate,
    required this.effectiveRate,
    this.rateProposal,
    this.since,
    this.endedAt,
  });

  String? get location {
    final parts = [neighborhood, city].whereType<String>().where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// O que espera a resposta da associação: pedido, contraproposta ou proposta de tabela da loja
  bool get awaitsAssociation => awaits(PartnershipSide.ASSOCIATION);

  /// Taxa que o cliente paga, para comparar com a tabela (nula = a loja cobra pela tabela)
  double? get customerFeeToCompare => passesDeliveryFee ? null : deliveryFee;

  factory AssociationPartnership.fromJson(Map<String, dynamic> json) => AssociationPartnership(
        id: json['id'],
        restaurantId: json['restaurantId'],
        restaurantName: json['restaurantName'] ?? '',
        slug: json['slug'],
        logoUrl: json['logoUrl'],
        neighborhood: json['neighborhood'],
        city: json['city'],
        state: json['state'],
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        passesDeliveryFee: json['deliveryFeeMode'] == 'PASS_THROUGH',
        coversDeliveryDifference: json['coversDeliveryDifference'] ?? false,
        status: PartnershipStatus.fromName(json['status']),
        requestedBy: PartnershipSide.fromName(json['requestedBy']),
        endedBy: PartnershipSide.fromName(json['endedBy']),
        awaitingSide: parseAwaitingSide(json),
        agreedRate: json['agreedRate'] != null ? DeliveryRate.fromJson(json['agreedRate']) : null,
        effectiveRate: DeliveryRate.fromJson(json['effectiveRate']),
        rateProposal: RateProposal.fromJson(json['rateProposal']),
        since: parseDate(json['since']),
        endedAt: parseDate(json['endedAt']),
      );
}
