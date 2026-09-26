import '../association/association.dart' show parseDate;
import '../delivery/courier_link.dart';
import '../order/order.dart' show OrderStatus, PaymentMethod;
import 'vehicle.dart';

enum CourierWorkStatus {
  OFFLINE('Offline'),
  ONLINE('Online'),
  BUSY('Em entrega');

  final String label;
  const CourierWorkStatus(this.label);

  static CourierWorkStatus fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OFFLINE);
}

enum ShiftMode {
  FREE,
  FIXED;

  static ShiftMode fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => FREE);
}

double? _toDouble(dynamic v) => (v as num?)?.toDouble();

/// Oferta de entrega com prazo para aceitar
class CourierOffer {
  final int offerId;
  final int orderId;
  final String? displayCode;
  final LinkRestaurant? restaurant;
  final String? deliveryAddress;
  final double? pickupDistanceKm;
  final double? deliveryDistanceKm;
  final double courierFee;
  final PaymentMethod? paymentMethod;
  final double? totalAmount;

  /// Momento local em que a oferta expira (calculado a partir dos segundos restantes do servidor)
  final DateTime expiresAt;

  CourierOffer({
    required this.offerId,
    required this.orderId,
    this.displayCode,
    this.restaurant,
    this.deliveryAddress,
    this.pickupDistanceKm,
    this.deliveryDistanceKm,
    required this.courierFee,
    this.paymentMethod,
    this.totalAmount,
    required this.expiresAt,
  });

  factory CourierOffer.fromJson(Map<String, dynamic> json) => CourierOffer(
        offerId: json['offerId'],
        orderId: json['orderId'],
        displayCode: json['displayCode'],
        restaurant: json['restaurant'] != null ? LinkRestaurant.fromJson(json['restaurant']) : null,
        deliveryAddress: json['deliveryAddress'],
        pickupDistanceKm: _toDouble(json['pickupDistanceKm']),
        deliveryDistanceKm: _toDouble(json['deliveryDistanceKm']),
        courierFee: _toDouble(json['courierFee']) ?? 0,
        paymentMethod: json['paymentMethod'] != null ? PaymentMethod.fromName(json['paymentMethod']) : null,
        totalAmount: _toDouble(json['totalAmount']),
        // Usa os segundos restantes em vez do horário do servidor: o relógio do aparelho pode estar errado
        expiresAt: DateTime.now().add(Duration(seconds: (json['secondsLeft'] as num?)?.toInt() ?? 30)),
      );
}

/// Entrega aceita pelo entregador
class CourierOrder {
  final int orderId;
  final String? displayCode;
  final OrderStatus status;
  final LinkRestaurant restaurant;
  final String? restaurantPhone;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final List<String> items;
  final String? notes;
  final PaymentMethod paymentMethod;
  final double totalAmount;
  final double? changeFor;
  final double? courierFee;
  final double? deliveryDistanceKm;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;

  CourierOrder({
    required this.orderId,
    this.displayCode,
    required this.status,
    required this.restaurant,
    this.restaurantPhone,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.items,
    this.notes,
    required this.paymentMethod,
    required this.totalAmount,
    this.changeFor,
    this.courierFee,
    this.deliveryDistanceKm,
    this.assignedAt,
    this.pickedUpAt,
  });

  factory CourierOrder.fromJson(Map<String, dynamic> json) => CourierOrder(
        orderId: json['orderId'],
        displayCode: json['displayCode'],
        status: OrderStatus.fromName(json['status']),
        restaurant: LinkRestaurant.fromJson(json['restaurant']),
        restaurantPhone: json['restaurantPhone'],
        customerName: json['customerName'],
        customerPhone: json['customerPhone'],
        deliveryAddress: json['deliveryAddress'],
        deliveryLatitude: _toDouble(json['deliveryLatitude']),
        deliveryLongitude: _toDouble(json['deliveryLongitude']),
        items: [for (final i in (json['items'] as List? ?? [])) i.toString()],
        notes: json['notes'],
        paymentMethod: PaymentMethod.fromName(json['paymentMethod']),
        totalAmount: _toDouble(json['totalAmount']) ?? 0,
        changeFor: _toDouble(json['changeFor']),
        courierFee: _toDouble(json['courierFee']),
        deliveryDistanceKm: _toDouble(json['deliveryDistanceKm']),
        assignedAt: parseDate(json['assignedAt']),
        pickedUpAt: parseDate(json['pickedUpAt']),
      );

  bool get pickedUp => status == OrderStatus.OUT_FOR_DELIVERY;
  bool get readyForPickup => status == OrderStatus.READY_FOR_PICKUP;
}

class CourierShift {
  final int id;
  final ShiftMode mode;
  final LinkRestaurant? restaurant;
  final Vehicle? vehicle;
  final DateTime? startedAt;
  final int deliveriesCount;

  CourierShift({required this.id, required this.mode, this.restaurant, this.vehicle, this.startedAt, required this.deliveriesCount});

  factory CourierShift.fromJson(Map<String, dynamic> json) => CourierShift(
        id: json['id'],
        mode: ShiftMode.fromName(json['mode']),
        restaurant: json['restaurant'] != null ? LinkRestaurant.fromJson(json['restaurant']) : null,
        vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
        startedAt: parseDate(json['startedAt']),
        deliveriesCount: json['deliveriesCount'] ?? 0,
      );

  bool get isFixed => mode == ShiftMode.FIXED;
}

/// Situação de trabalho do entregador
class CourierWorkState {
  final int deliveryPersonId;
  final CourierWorkStatus workStatus;
  final CourierShift? shift;
  final CourierOffer? pendingOffer;
  final CourierOrder? activeOrder;
  final double earnedToday;
  final int deliveriesToday;
  final List<String> blockers;

  CourierWorkState({
    required this.deliveryPersonId,
    required this.workStatus,
    this.shift,
    this.pendingOffer,
    this.activeOrder,
    required this.earnedToday,
    required this.deliveriesToday,
    required this.blockers,
  });

  factory CourierWorkState.fromJson(Map<String, dynamic> json) => CourierWorkState(
        deliveryPersonId: json['deliveryPersonId'],
        workStatus: CourierWorkStatus.fromName(json['workStatus']),
        shift: json['shift'] != null ? CourierShift.fromJson(json['shift']) : null,
        pendingOffer: json['pendingOffer'] != null ? CourierOffer.fromJson(json['pendingOffer']) : null,
        activeOrder: json['activeOrder'] != null ? CourierOrder.fromJson(json['activeOrder']) : null,
        earnedToday: _toDouble(json['earnedToday']) ?? 0,
        deliveriesToday: json['deliveriesToday'] ?? 0,
        blockers: [for (final b in (json['blockers'] as List? ?? [])) b.toString()],
      );

  bool get isWorking => workStatus != CourierWorkStatus.OFFLINE;
}
