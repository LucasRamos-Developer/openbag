import '../order/order.dart';

DateTime? _date(dynamic v) => v != null ? DateTime.tryParse(v as String) : null;

/// Situação de uma rota (ou de um pedido sozinho) no painel
enum RouteStatus {
  PLANNED('Montando'),
  DISPATCHING('Procurando entregador'),
  ASSIGNED('Com entregador'),
  IN_PROGRESS('Em entrega'),
  DONE('Concluída'),
  CANCELLED('Cancelada');

  final String label;

  const RouteStatus(this.label);

  static RouteStatus fromName(String? name) => values.firstWhere((s) => s.name == name, orElse: () => PLANNED);
}

class DeliveryRouteSettings {
  final bool enabled;
  final int maxOrders;
  final int maxHoldMinutes;
  final int leadMinutes;

  DeliveryRouteSettings({required this.enabled, required this.maxOrders, required this.maxHoldMinutes, required this.leadMinutes});

  factory DeliveryRouteSettings.fromJson(Map<String, dynamic> json) => DeliveryRouteSettings(
        enabled: json['enabled'] ?? true,
        maxOrders: json['maxOrders'] ?? 3,
        maxHoldMinutes: json['maxHoldMinutes'] ?? 8,
        leadMinutes: json['leadMinutes'] ?? 10,
      );

  Map<String, dynamic> toJson() =>
      {'enabled': enabled, 'maxOrders': maxOrders, 'maxHoldMinutes': maxHoldMinutes, 'leadMinutes': leadMinutes};

  DeliveryRouteSettings copyWith({bool? enabled, int? maxOrders, int? maxHoldMinutes, int? leadMinutes}) => DeliveryRouteSettings(
        enabled: enabled ?? this.enabled,
        maxOrders: maxOrders ?? this.maxOrders,
        maxHoldMinutes: maxHoldMinutes ?? this.maxHoldMinutes,
        leadMinutes: leadMinutes ?? this.leadMinutes,
      );
}

/// Painel de rotas: o que está montando e o que está com entregador
class RoutesBoard {
  final DeliveryRouteSettings settings;
  final double? storeLatitude;
  final double? storeLongitude;
  final List<RouteCard> planning;
  final List<RouteCard> active;

  RoutesBoard({required this.settings, this.storeLatitude, this.storeLongitude, required this.planning, required this.active});

  List<RouteCard> get all => [...planning, ...active];

  factory RoutesBoard.fromJson(Map<String, dynamic> json) => RoutesBoard(
        settings: DeliveryRouteSettings.fromJson(json['settings'] ?? const {}),
        storeLatitude: (json['storeLatitude'] as num?)?.toDouble(),
        storeLongitude: (json['storeLongitude'] as num?)?.toDouble(),
        planning: [for (final c in json['planning'] as List? ?? []) RouteCard.fromJson(c)],
        active: [for (final c in json['active'] as List? ?? []) RouteCard.fromJson(c)],
      );
}

/// Uma rota ou um pedido sozinho ([routeId] nulo)
class RouteCard {
  final int? routeId;
  final RouteStatus status;
  final bool manual;
  final String? courierName;
  final CourierKind? courierKind;
  final double? totalDistanceKm;
  final double? savedDistanceKm;

  /// Quando o entregador será chamado (ainda montando)
  final DateTime? dispatchAt;
  final String? waitReason;
  final DateTime? searchingCourierSince;
  final List<RouteStop> stops;

  RouteCard({
    this.routeId,
    required this.status,
    this.manual = false,
    this.courierName,
    this.courierKind,
    this.totalDistanceKm,
    this.savedDistanceKm,
    this.dispatchAt,
    this.waitReason,
    this.searchingCourierSince,
    required this.stops,
  });

  bool get isRoute => routeId != null;
  bool get hasCourier => courierName != null;
  RouteStop get lead => stops.first;

  factory RouteCard.fromJson(Map<String, dynamic> json) => RouteCard(
        routeId: json['routeId'],
        status: RouteStatus.fromName(json['status']),
        manual: json['origin'] == 'MANUAL',
        courierName: json['courierName'],
        courierKind: CourierKind.fromName(json['courierKind']),
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble(),
        savedDistanceKm: (json['savedDistanceKm'] as num?)?.toDouble(),
        dispatchAt: _date(json['dispatchAt']),
        waitReason: json['waitReason'],
        searchingCourierSince: _date(json['searchingCourierSince']),
        stops: [for (final s in json['stops'] as List? ?? []) RouteStop.fromJson(s)],
      );
}

class RouteStop {
  final int orderId;
  final String? displayCode;
  final OrderStatus status;
  final String? neighborhood;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? readyAt;
  final DateTime? expectedReadyAt;
  final DateTime? pickedUpAt;
  final bool solo;

  RouteStop({
    required this.orderId,
    this.displayCode,
    required this.status,
    this.neighborhood,
    this.address,
    this.latitude,
    this.longitude,
    this.readyAt,
    this.expectedReadyAt,
    this.pickedUpAt,
    this.solo = false,
  });

  bool get ready => readyAt != null || status == OrderStatus.READY_FOR_PICKUP;
  bool get hasLocation => latitude != null && longitude != null;

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
        orderId: json['orderId'],
        displayCode: json['displayCode'],
        status: OrderStatus.fromName(json['status']),
        neighborhood: json['neighborhood'],
        address: json['address'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        readyAt: _date(json['readyAt']),
        expectedReadyAt: _date(json['expectedReadyAt']),
        pickedUpAt: _date(json['pickedUpAt']),
        solo: json['solo'] ?? false,
      );
}
