import '../courier/courier_earnings.dart' show EarningsDay;
import '../order/order_incident.dart';

double _money(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// Relatório da associação no período. O cooperado recebe sem [byMember] e com [mine].
class AssociationReport {
  final String associationName;
  final DateTime from;
  final DateTime to;
  final AssociationReportSummary summary;
  final List<EarningsDay> daily;
  final List<AssociationMemberLine>? byMember;
  final List<AssociationRestaurantLine> byRestaurant;
  final AssociationIncidents incidents;
  final ({int deliveries, double earnings})? mine;

  AssociationReport({
    required this.associationName,
    required this.from,
    required this.to,
    required this.summary,
    required this.daily,
    this.byMember,
    required this.byRestaurant,
    required this.incidents,
    this.mine,
  });

  factory AssociationReport.fromJson(Map<String, dynamic> json) {
    final mine = json['mine'] as Map<String, dynamic>?;
    return AssociationReport(
      associationName: json['associationName'] ?? '',
      from: DateTime.parse(json['from']),
      to: DateTime.parse(json['to']),
      summary: AssociationReportSummary.fromJson(json['summary']),
      daily: [
        for (final d in json['daily'] as List? ?? [])
          EarningsDay(DateTime.parse(d['date']), _money(d['earnings']), (d['deliveries'] as num?)?.toInt() ?? 0),
      ],
      byMember: json['byMember'] == null
          ? null
          : [for (final m in json['byMember'] as List) AssociationMemberLine.fromJson(m)],
      byRestaurant: [for (final r in json['byRestaurant'] as List? ?? []) AssociationRestaurantLine.fromJson(r)],
      incidents: AssociationIncidents.fromJson(json['incidents'] ?? const {}),
      mine: mine == null
          ? null
          : (deliveries: (mine['deliveries'] as num?)?.toInt() ?? 0, earnings: _money(mine['earnings'])),
    );
  }
}

/// [earnings] é o total pago aos cooperados (100% da tabela); [restaurantSubsidy] é a parte que as lojas assumiram
class AssociationReportSummary {
  final int deliveries;
  final double earnings;
  final double distanceKm;
  final int members;
  final int restaurants;
  final double restaurantSubsidy;

  AssociationReportSummary({
    required this.deliveries,
    required this.earnings,
    required this.distanceKm,
    required this.members,
    required this.restaurants,
    required this.restaurantSubsidy,
  });

  factory AssociationReportSummary.fromJson(Map<String, dynamic> json) => AssociationReportSummary(
        deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
        earnings: _money(json['earnings']),
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        members: (json['members'] as num?)?.toInt() ?? 0,
        restaurants: (json['restaurants'] as num?)?.toInt() ?? 0,
        restaurantSubsidy: _money(json['restaurantSubsidy']),
      );
}

class AssociationMemberLine {
  final int deliveryPersonId;
  final String name;
  final int? memberNumber;
  final int deliveries;
  final double earnings;
  final double distanceKm;

  AssociationMemberLine({
    required this.deliveryPersonId,
    required this.name,
    this.memberNumber,
    required this.deliveries,
    required this.earnings,
    required this.distanceKm,
  });

  factory AssociationMemberLine.fromJson(Map<String, dynamic> json) => AssociationMemberLine(
        deliveryPersonId: json['deliveryPersonId'],
        name: json['name'] ?? '',
        memberNumber: (json['memberNumber'] as num?)?.toInt(),
        deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
        earnings: _money(json['earnings']),
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      );
}

/// [agreedRate]: a loja tem tabela especial com a associação
class AssociationRestaurantLine {
  final int restaurantId;
  final String name;
  final String? slug;
  final String? logoUrl;
  final int deliveries;
  final double earnings;
  final double restaurantSubsidy;
  final bool agreedRate;

  AssociationRestaurantLine({
    required this.restaurantId,
    required this.name,
    this.slug,
    this.logoUrl,
    required this.deliveries,
    required this.earnings,
    required this.restaurantSubsidy,
    required this.agreedRate,
  });

  factory AssociationRestaurantLine.fromJson(Map<String, dynamic> json) => AssociationRestaurantLine(
        restaurantId: json['restaurantId'],
        name: json['name'] ?? '',
        slug: json['slug'],
        logoUrl: json['logoUrl'],
        deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
        earnings: _money(json['earnings']),
        restaurantSubsidy: _money(json['restaurantSubsidy']),
        agreedRate: json['agreedRate'] ?? false,
      );
}

typedef IncidentCount = ({IncidentType type, int count});

List<IncidentCount> _typeCounts(dynamic list) => [
      for (final t in list as List? ?? [])
        (type: IncidentType.fromName(t['type']), count: (t['count'] as num?)?.toInt() ?? 0),
    ];

/// Ocorrências relatadas pelos cooperados no período, por tipo e por loja (a mais citada primeiro).
/// Nunca por cooperado: ocorrência não é nota nem penalidade.
class AssociationIncidents {
  final int total;
  final List<IncidentCount> byType;
  final List<AssociationRestaurantIncidents> byRestaurant;

  AssociationIncidents({required this.total, required this.byType, required this.byRestaurant});

  factory AssociationIncidents.fromJson(Map<String, dynamic> json) => AssociationIncidents(
        total: (json['total'] as num?)?.toInt() ?? 0,
        byType: _typeCounts(json['byType']),
        byRestaurant: [
          for (final r in json['byRestaurant'] as List? ?? []) AssociationRestaurantIncidents.fromJson(r),
        ],
      );
}

class AssociationRestaurantIncidents {
  final int restaurantId;
  final String name;
  final String? logoUrl;
  final int total;
  final List<IncidentCount> byType;

  AssociationRestaurantIncidents({
    required this.restaurantId,
    required this.name,
    this.logoUrl,
    required this.total,
    required this.byType,
  });

  factory AssociationRestaurantIncidents.fromJson(Map<String, dynamic> json) => AssociationRestaurantIncidents(
        restaurantId: json['restaurantId'],
        name: json['name'] ?? '',
        logoUrl: json['logoUrl'],
        total: (json['total'] as num?)?.toInt() ?? 0,
        byType: _typeCounts(json['byType']),
      );
}
