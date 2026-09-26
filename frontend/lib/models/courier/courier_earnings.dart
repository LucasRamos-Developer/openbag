import '../association/association.dart' show parseDate;
import 'courier_work.dart' show ShiftMode;

double _money(dynamic v) => (v as num?)?.toDouble() ?? 0;

class EarningsTotal {
  final double amount;
  final int deliveries;

  const EarningsTotal(this.amount, this.deliveries);

  factory EarningsTotal.fromJson(Map<String, dynamic>? json) =>
      EarningsTotal(_money(json?['amount']), (json?['deliveries'] as num?)?.toInt() ?? 0);
}

class EarningsDay {
  final DateTime date;
  final double amount;
  final int deliveries;

  EarningsDay(this.date, this.amount, this.deliveries);

  factory EarningsDay.fromJson(Map<String, dynamic> json) =>
      EarningsDay(DateTime.parse(json['date']), _money(json['amount']), (json['deliveries'] as num?)?.toInt() ?? 0);
}

class EarningsDelivery {
  final int orderId;
  final String? displayCode;
  final DateTime? deliveredAt;
  final String restaurantName;
  final double? distanceKm;
  final double courierFee;

  EarningsDelivery({
    required this.orderId,
    this.displayCode,
    this.deliveredAt,
    required this.restaurantName,
    this.distanceKm,
    required this.courierFee,
  });

  factory EarningsDelivery.fromJson(Map<String, dynamic> json) => EarningsDelivery(
        orderId: json['orderId'],
        displayCode: json['displayCode'],
        deliveredAt: parseDate(json['deliveredAt']),
        restaurantName: json['restaurantName'] ?? '',
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        courierFee: _money(json['courierFee']),
      );
}

/// Ganhos do entregador: resumo, série diária e entregas do período
class CourierEarnings {
  final EarningsTotal today;
  final EarningsTotal week;
  final EarningsTotal month;
  final EarningsTotal period;
  final List<EarningsDay> daily;
  final List<EarningsDelivery> deliveries;

  CourierEarnings({
    required this.today,
    required this.week,
    required this.month,
    required this.period,
    required this.daily,
    required this.deliveries,
  });

  factory CourierEarnings.fromJson(Map<String, dynamic> json) => CourierEarnings(
        today: EarningsTotal.fromJson(json['today']),
        week: EarningsTotal.fromJson(json['week']),
        month: EarningsTotal.fromJson(json['month']),
        period: EarningsTotal.fromJson(json['period']),
        daily: [for (final d in (json['daily'] as List? ?? [])) EarningsDay.fromJson(d)],
        deliveries: [for (final d in (json['deliveries'] as List? ?? [])) EarningsDelivery.fromJson(d)],
      );
}

/// Restaurante em que o entregador já trabalhou
class WorkedRestaurant {
  final int restaurantId;
  final String name;
  final String? slug;
  final String? logoUrl;
  final int deliveries;
  final DateTime? firstDeliveryAt;
  final DateTime? lastDeliveryAt;
  final bool fixed;

  WorkedRestaurant({
    required this.restaurantId,
    required this.name,
    this.slug,
    this.logoUrl,
    required this.deliveries,
    this.firstDeliveryAt,
    this.lastDeliveryAt,
    required this.fixed,
  });

  factory WorkedRestaurant.fromJson(Map<String, dynamic> json) => WorkedRestaurant(
        restaurantId: json['restaurantId'],
        name: json['name'] ?? '',
        slug: json['slug'],
        logoUrl: json['logoUrl'],
        deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
        firstDeliveryAt: parseDate(json['firstDeliveryAt']),
        lastDeliveryAt: parseDate(json['lastDeliveryAt']),
        fixed: json['fixed'] ?? false,
      );
}

class ShiftEntry {
  final int id;
  final ShiftMode mode;
  final String? restaurantName;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int deliveries;

  ShiftEntry({required this.id, required this.mode, this.restaurantName, this.startedAt, this.endedAt, required this.deliveries});

  factory ShiftEntry.fromJson(Map<String, dynamic> json) => ShiftEntry(
        id: json['id'],
        mode: ShiftMode.fromName(json['mode']),
        restaurantName: json['restaurantName'],
        startedAt: parseDate(json['startedAt']),
        endedAt: parseDate(json['endedAt']),
        deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
      );
}

class WorkHistory {
  final List<WorkedRestaurant> restaurants;
  final List<ShiftEntry> recentShifts;

  WorkHistory({required this.restaurants, required this.recentShifts});

  factory WorkHistory.fromJson(Map<String, dynamic> json) => WorkHistory(
        restaurants: [for (final r in (json['restaurants'] as List? ?? [])) WorkedRestaurant.fromJson(r)],
        recentShifts: [for (final s in (json['recentShifts'] as List? ?? [])) ShiftEntry.fromJson(s)],
      );
}
