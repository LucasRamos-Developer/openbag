import '../association/association.dart' show parseDate;
import 'courier_work.dart' show ShiftMode;

double _money(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// Ganho, entregas e km rodados (com o pedido e até a retirada)
class EarningsTotal {
  final double amount;
  final int deliveries;
  final double distanceKm;

  const EarningsTotal(this.amount, this.deliveries, [this.distanceKm = 0]);

  factory EarningsTotal.fromJson(Map<String, dynamic>? json) => EarningsTotal(_money(json?['amount']),
      (json?['deliveries'] as num?)?.toInt() ?? 0, (json?['distanceKm'] as num?)?.toDouble() ?? 0);
}

/// Km, tempo e médias do período, só para o próprio entregador. Médias sem base vêm nulas (a tela mostra "—").
class CourierWorkStats {
  final double deliveryKm;
  final double pickupKm;
  final double totalKm;
  final int onlineMinutes;
  final int deliveringMinutes;
  final double? amountPerDelivery;
  final double? kmPerDelivery;
  final int? minutesPerDelivery;
  final double? perKm;
  final double? perHour;

  CourierWorkStats({
    required this.deliveryKm,
    required this.pickupKm,
    required this.totalKm,
    required this.onlineMinutes,
    required this.deliveringMinutes,
    this.amountPerDelivery,
    this.kmPerDelivery,
    this.minutesPerDelivery,
    this.perKm,
    this.perHour,
  });

  factory CourierWorkStats.fromJson(Map<String, dynamic> json) {
    final avg = json['perDelivery'] as Map<String, dynamic>?;
    double? optMoney(dynamic v) => v == null ? null : _money(v);
    return CourierWorkStats(
      deliveryKm: (json['deliveryKm'] as num?)?.toDouble() ?? 0,
      pickupKm: (json['pickupKm'] as num?)?.toDouble() ?? 0,
      totalKm: (json['totalKm'] as num?)?.toDouble() ?? 0,
      onlineMinutes: (json['onlineMinutes'] as num?)?.toInt() ?? 0,
      deliveringMinutes: (json['deliveringMinutes'] as num?)?.toInt() ?? 0,
      amountPerDelivery: optMoney(avg?['amount']),
      kmPerDelivery: (avg?['distanceKm'] as num?)?.toDouble(),
      minutesPerDelivery: (avg?['minutes'] as num?)?.toInt(),
      perKm: optMoney(json['perKm']),
      perHour: optMoney(json['perHour']),
    );
  }
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
  final CourierWorkStats? stats;

  /// Resultado estimado; nulo quando nenhum veículo usado tem custo informado
  final VehicleCostEstimate? cost;

  CourierEarnings({
    required this.today,
    required this.week,
    required this.month,
    required this.period,
    required this.daily,
    required this.deliveries,
    this.stats,
    this.cost,
  });

  factory CourierEarnings.fromJson(Map<String, dynamic> json) => CourierEarnings(
        today: EarningsTotal.fromJson(json['today']),
        week: EarningsTotal.fromJson(json['week']),
        month: EarningsTotal.fromJson(json['month']),
        period: EarningsTotal.fromJson(json['period']),
        daily: [for (final d in (json['daily'] as List? ?? [])) EarningsDay.fromJson(d)],
        deliveries: [for (final d in (json['deliveries'] as List? ?? [])) EarningsDelivery.fromJson(d)],
        stats: json['stats'] != null ? CourierWorkStats.fromJson(json['stats']) : null,
        cost: json['cost'] != null ? VehicleCostEstimate.fromJson(json['cost']) : null,
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

/// Resultado estimado do período: ganho menos combustível, manutenção e depreciação. Estimativa, não valor contábil.
/// Uma parte nula não foi informada em nenhum veículo usado.
class VehicleCostEstimate {
  final double distanceKm;
  final double revenue;
  final double? fuel;
  final double? maintenance;
  final double? depreciation;
  final double total;
  final double result;
  final bool complete;
  final List<({int vehicleId, String name, double distanceKm, bool complete})> vehicles;

  VehicleCostEstimate({
    required this.distanceKm,
    required this.revenue,
    this.fuel,
    this.maintenance,
    this.depreciation,
    required this.total,
    required this.result,
    required this.complete,
    required this.vehicles,
  });

  factory VehicleCostEstimate.fromJson(Map<String, dynamic> json) {
    double? opt(dynamic v) => v == null ? null : _money(v);
    return VehicleCostEstimate(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      revenue: _money(json['revenue']),
      fuel: opt(json['fuel']),
      maintenance: opt(json['maintenance']),
      depreciation: opt(json['depreciation']),
      total: _money(json['total']),
      result: _money(json['result']),
      complete: json['complete'] ?? false,
      vehicles: [
        for (final v in json['vehicles'] as List? ?? [])
          (
            vehicleId: v['vehicleId'] as int,
            name: (v['name'] ?? '') as String,
            distanceKm: (v['distanceKm'] as num?)?.toDouble() ?? 0,
            complete: (v['complete'] ?? false) as bool,
          ),
      ],
    );
  }
}
