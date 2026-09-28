import '../association/association.dart' show parseDate;
import 'delivery_rate.dart';
import 'partnership.dart';

export 'partnership.dart';

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

/// Parceria vista pela loja: a associação, a situação e a tabela que vale na loja
class Partner extends PartnershipInfo {
  @override
  final int id;
  final int organizationId;
  final String name;
  final String? logoUrl;
  final String? city;
  final String? state;
  @override
  final PartnershipStatus status;
  @override
  final PartnershipSide? requestedBy;
  @override
  final PartnershipSide? endedBy;
  @override
  final PartnershipSide? awaitingSide;

  /// Tabela padrão da associação
  final DeliveryRate deliveryRate;
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
  final bool exceedsDeliveryFee;

  Partner({
    required this.id,
    required this.organizationId,
    required this.name,
    this.logoUrl,
    this.city,
    this.state,
    required this.status,
    this.requestedBy,
    this.endedBy,
    this.awaitingSide,
    required this.deliveryRate,
    this.agreedRate,
    required this.effectiveRate,
    this.rateProposal,
    this.since,
    this.endedAt,
    required this.exceedsDeliveryFee,
  });

  String? get location => city == null ? null : [city, state].whereType<String>().join(' - ');

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
        id: json['id'],
        organizationId: json['organizationId'],
        name: json['name'] ?? '',
        logoUrl: json['logoUrl'],
        city: json['city'],
        state: json['state'],
        status: PartnershipStatus.fromName(json['status']),
        requestedBy: PartnershipSide.fromName(json['requestedBy']),
        endedBy: PartnershipSide.fromName(json['endedBy']),
        awaitingSide: parseAwaitingSide(json),
        deliveryRate: DeliveryRate.fromJson(json['deliveryRate']),
        agreedRate: json['agreedRate'] != null ? DeliveryRate.fromJson(json['agreedRate']) : null,
        effectiveRate: DeliveryRate.fromJson(json['effectiveRate'] ?? json['deliveryRate']),
        rateProposal: RateProposal.fromJson(json['rateProposal']),
        since: parseDate(json['since']),
        endedAt: parseDate(json['endedAt']),
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

  /// A loja repassa a taxa ao cliente: ele paga pela distância (maior tabela) e o entregador recebe tudo
  final bool passesDeliveryFee;

  /// Se repassar: o "a partir de" da vitrine e quanto o cliente pagaria em algumas distâncias
  final double? deliveryFeeFrom;
  final List<({double distanceKm, double fee})> deliveryFeeSimulation;

  /// Parcerias ativas
  final List<Partner> partners;

  /// Pedidos pendentes (da loja ou convites das associações)
  final List<Partner> partnershipRequests;

  /// Recusadas ou encerradas, mais recentes primeiro
  final List<Partner> partnershipHistory;

  /// Pedidos e propostas de tabela que esperam a resposta da loja
  final int pendingPartnershipActions;

  /// A associação encerrou a última parceria e a loja passou a receber de qualquer entregador
  final DateTime? partnersEndedNoticeAt;
  final int activeFixedCouriers;
  final int pendingFixedCouriers;

  /// Entregador livre que não aparece: minutos até a loja poder trocá-lo
  final int courierNoShowMinutes;

  /// Taxa que o cliente paga, para comparar com a tabela dos parceiros (nula = cobra pela tabela)
  double? get customerFeeToCompare => passesDeliveryFee ? null : deliveryFee;

  RestaurantDeliverySettings({
    required this.courierPolicy,
    required this.fallbackToOpen,
    required this.coversDeliveryDifference,
    this.coversDeliveryDifferenceAcceptedAt,
    required this.deliveryFee,
    this.passesDeliveryFee = false,
    this.deliveryFeeFrom,
    this.deliveryFeeSimulation = const [],
    required this.partners,
    this.partnershipRequests = const [],
    this.partnershipHistory = const [],
    this.pendingPartnershipActions = 0,
    this.partnersEndedNoticeAt,
    required this.activeFixedCouriers,
    required this.pendingFixedCouriers,
    this.courierNoShowMinutes = 10,
  });

  factory RestaurantDeliverySettings.fromJson(Map<String, dynamic> json) => RestaurantDeliverySettings(
        courierPolicy: CourierPolicy.fromName(json['courierPolicy']),
        fallbackToOpen: json['fallbackToOpen'] ?? false,
        coversDeliveryDifference: json['coversDeliveryDifference'] ?? false,
        coversDeliveryDifferenceAcceptedAt: parseDate(json['coversDeliveryDifferenceAcceptedAt']),
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        passesDeliveryFee: json['deliveryFeeMode'] == 'PASS_THROUGH',
        deliveryFeeFrom: (json['deliveryFeeFrom'] as num?)?.toDouble(),
        deliveryFeeSimulation: [
          for (final sample in (json['deliveryFeeSimulation'] as List? ?? []))
            (distanceKm: (sample['distanceKm'] as num).toDouble(), fee: (sample['fee'] as num).toDouble()),
        ],
        partners: [for (final p in (json['partners'] as List? ?? [])) Partner.fromJson(p)],
        partnershipRequests: [for (final p in (json['partnershipRequests'] as List? ?? [])) Partner.fromJson(p)],
        partnershipHistory: [for (final p in (json['partnershipHistory'] as List? ?? [])) Partner.fromJson(p)],
        pendingPartnershipActions: json['pendingPartnershipActions'] ?? 0,
        partnersEndedNoticeAt: parseDate(json['partnersEndedNoticeAt']),
        activeFixedCouriers: json['activeFixedCouriers'] ?? 0,
        pendingFixedCouriers: json['pendingFixedCouriers'] ?? 0,
        courierNoShowMinutes: json['courierNoShowMinutes'] ?? 10,
      );
}
