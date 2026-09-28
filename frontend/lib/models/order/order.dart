import 'package:flutter/material.dart';
import '../courier/vehicle_type.dart';
import 'order_review.dart';

double _money(dynamic value) => (value as num?)?.toDouble() ?? 0;
DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value) : null;

/// Formas de pagamento na entrega (MVP sem pagamento online)
enum PaymentMethod {
  PIX('Pix na entrega', Icons.pix),
  CREDIT_CARD('Cartão de crédito (maquininha)', Icons.credit_card),
  DEBIT_CARD('Cartão de débito (maquininha)', Icons.credit_card_outlined),
  CASH('Dinheiro', Icons.payments_outlined),
  FOOD_VOUCHER('Vale-refeição (maquininha)', Icons.restaurant_outlined);

  final String label;
  final IconData icon;
  const PaymentMethod(this.label, this.icon);

  static PaymentMethod fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => PIX);
}

enum OrderStatus {
  PENDING('Aguardando o restaurante', 'O restaurante vai confirmar seu pedido em instantes.'),
  CONFIRMED('Pedido confirmado', 'O restaurante aceitou seu pedido.'),
  PREPARING('Em preparo', 'Seu pedido está sendo preparado.'),
  READY_FOR_PICKUP('Pronto', 'Seu pedido está pronto e aguarda o entregador.'),
  OUT_FOR_DELIVERY('Saiu para entrega', 'Seu pedido está a caminho.'),
  DELIVERED('Entregue', 'Pedido entregue. Bom apetite!'),
  CANCELLED('Cancelado', 'Este pedido foi cancelado.');

  final String label;
  final String description;
  const OrderStatus(this.label, this.description);

  bool get isFinal => this == DELIVERED || this == CANCELLED;

  static OrderStatus fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => PENDING);

  /// Etapas exibidas na linha do tempo do cliente (cancelado é tratado à parte)
  static const progress = [PENDING, CONFIRMED, PREPARING, READY_FOR_PICKUP, OUT_FOR_DELIVERY, DELIVERED];
}

class Order {
  final int id;
  final String orderNumber;
  final String? displayCode;
  final OrderStatus status;
  final OrderRestaurant restaurant;
  final String? customerName;
  final String? customerPhone;
  final List<OrderLine> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double? changeFor;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? notes;
  final int? estimatedDeliveryTime;
  final DateTime? createdAt;
  final DateTime? acceptDeadline;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final List<OrderTimelineEntry> timeline;
  final OrderCourier? courier;
  final CourierKind? courierKind;

  /// Entregador da equipe própria da loja (sem o app)
  final OrderStaffCourier? staffCourier;

  /// Entregador livre: a partir de quando a loja pode trocá-lo se ele não aparecer
  final DateTime? reassignableAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;

  /// Aceito e sem entregador disponível desde este momento
  final DateTime? searchingCourierSince;

  /// Posição do entregador (só para o cliente, e só quando é a vez deste pedido)
  final GeoPosition? courierLocation;

  /// Avaliação feita pelo cliente
  final OrderReview? review;

  /// Até quando o cliente ainda pode avaliar (nulo: não pode)
  final DateTime? reviewableUntil;

  Order({
    required this.id,
    required this.orderNumber,
    this.displayCode,
    required this.status,
    required this.restaurant,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentMethod,
    this.changeFor,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.notes,
    this.estimatedDeliveryTime,
    this.createdAt,
    this.acceptDeadline,
    this.acceptedAt,
    this.readyAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.timeline,
    this.courier,
    this.courierKind,
    this.staffCourier,
    this.reassignableAt,
    this.assignedAt,
    this.pickedUpAt,
    this.searchingCourierSince,
    this.courierLocation,
    this.review,
    this.reviewableUntil,
  });

  /// Antes da retirada: ainda pode receber ou trocar de entregador
  bool get beforePickup =>
      pickedUpAt == null &&
      (status == OrderStatus.CONFIRMED || status == OrderStatus.PREPARING || status == OrderStatus.READY_FOR_PICKUP);

  /// Aceito e ainda sem ninguém para levar
  bool get awaitingCourier => courier == null && staffCourier == null && beforePickup;

  /// Nome de quem está com o pedido (app ou equipe)
  String? get courierName => courier?.fullName ?? staffCourier?.name;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Quando cada etapa aconteceu (a partir da linha do tempo)
  DateTime? reachedAt(OrderStatus status) =>
      timeline.where((t) => t.status == status).map((t) => t.at).whereType<DateTime>().firstOrNull;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        orderNumber: json['orderNumber'] ?? '',
        displayCode: json['displayCode'],
        status: OrderStatus.fromName(json['status']),
        restaurant: OrderRestaurant.fromJson(json['restaurant'] ?? const {}),
        customerName: json['customerName'],
        customerPhone: json['customerPhone'],
        items: (json['items'] as List? ?? []).map((e) => OrderLine.fromJson(e)).toList(),
        subtotal: _money(json['subtotal']),
        deliveryFee: _money(json['deliveryFee']),
        totalAmount: _money(json['totalAmount']),
        paymentMethod: PaymentMethod.fromName(json['paymentMethod']),
        changeFor: json['changeFor'] != null ? _money(json['changeFor']) : null,
        deliveryAddress: json['deliveryAddress'],
        deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
        deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
        notes: json['notes'],
        estimatedDeliveryTime: json['estimatedDeliveryTime'],
        createdAt: _date(json['createdAt']),
        acceptDeadline: _date(json['acceptDeadline']),
        acceptedAt: _date(json['acceptedAt']),
        readyAt: _date(json['readyAt']),
        dispatchedAt: _date(json['dispatchedAt']),
        deliveredAt: _date(json['deliveredAt']),
        cancelledBy: json['cancelledBy'],
        cancellationReason: json['cancellationReason'],
        timeline: (json['timeline'] as List? ?? []).map((e) => OrderTimelineEntry.fromJson(e)).toList(),
        courier: json['courier'] != null ? OrderCourier.fromJson(json['courier']) : null,
        courierKind: CourierKind.fromName(json['courierKind']),
        staffCourier: json['staffCourier'] != null ? OrderStaffCourier.fromJson(json['staffCourier']) : null,
        reassignableAt: _date(json['reassignableAt']),
        assignedAt: _date(json['assignedAt']),
        pickedUpAt: _date(json['pickedUpAt']),
        searchingCourierSince: _date(json['searchingCourierSince']),
        courierLocation: json['courierLocation'] != null ? GeoPosition.fromJson(json['courierLocation']) : null,
        review: json['review'] != null ? OrderReview.fromJson(json['review']) : null,
        reviewableUntil: _date(json['reviewableUntil']),
      );
}

/// Ponto no mapa com o momento em que foi registrado (posição do entregador)
class GeoPosition {
  final double latitude;
  final double longitude;
  final DateTime? at;

  const GeoPosition({required this.latitude, required this.longitude, this.at});

  factory GeoPosition.fromJson(Map<String, dynamic> json) => GeoPosition(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        at: _date(json['at']),
      );
}

/// De onde vem quem está com o pedido: fixo em check-in, livre do app ou equipe própria
enum CourierKind {
  FIXED('Fixo'),
  FREE('Livre'),
  STAFF('Equipe da loja');

  final String label;

  const CourierKind(this.label);

  static CourierKind? fromName(String? name) => values.where((k) => k.name == name).firstOrNull;
}

/// Entregador da equipe própria da loja atribuído ao pedido
class OrderStaffCourier {
  final int id;
  final String name;
  final String? phone;

  OrderStaffCourier({required this.id, required this.name, this.phone});

  factory OrderStaffCourier.fromJson(Map<String, dynamic> json) =>
      OrderStaffCourier(id: json['id'], name: json['name'] ?? '', phone: json['phone']);
}

/// Entregador do app atribuído ao pedido
class OrderCourier {
  final int deliveryPersonId;
  final String fullName;
  final String? photoUrl;
  final String? slug;
  final String? phoneNumber;
  final VehicleType? vehicleType;
  final String? vehicleDescription;
  final String? vehiclePlate;

  OrderCourier({
    required this.deliveryPersonId,
    required this.fullName,
    this.photoUrl,
    this.slug,
    this.phoneNumber,
    this.vehicleType,
    this.vehicleDescription,
    this.vehiclePlate,
  });

  factory OrderCourier.fromJson(Map<String, dynamic> json) => OrderCourier(
        deliveryPersonId: json['deliveryPersonId'],
        fullName: json['fullName'] ?? '',
        photoUrl: json['photoUrl'],
        slug: json['slug'],
        phoneNumber: json['phoneNumber'],
        vehicleType: json['vehicleType'] != null ? VehicleType.fromName(json['vehicleType']) : null,
        vehicleDescription: json['vehicleDescription'],
        vehiclePlate: json['vehiclePlate'],
      );

  String get vehicleLine => [
        if (vehicleType != null) vehicleType!.label,
        if (vehicleDescription?.isNotEmpty == true) vehicleDescription!,
        if (vehiclePlate != null) vehiclePlate!,
      ].join(' · ');
}

class OrderRestaurant {
  final int? id;
  final String name;
  final String? slug;
  final String? logoUrl;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  OrderRestaurant({this.id, required this.name, this.slug, this.logoUrl, this.phoneNumber, this.latitude, this.longitude});

  factory OrderRestaurant.fromJson(Map<String, dynamic> json) => OrderRestaurant(
        id: json['id'],
        name: json['name'] ?? '',
        slug: json['slug'],
        logoUrl: json['logoUrl'],
        phoneNumber: json['phoneNumber'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class OrderLine {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final List<OrderLineOption> customizations;

  OrderLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.customizations,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        name: json['name'] ?? '',
        quantity: json['quantity'] ?? 1,
        unitPrice: _money(json['unitPrice']),
        totalPrice: _money(json['totalPrice']),
        notes: json['notes'],
        customizations: (json['customizations'] as List? ?? []).map((e) => OrderLineOption.fromJson(e)).toList(),
      );
}

class OrderLineOption {
  final String groupName;
  final String optionName;
  final double price;

  OrderLineOption({required this.groupName, required this.optionName, required this.price});

  factory OrderLineOption.fromJson(Map<String, dynamic> json) => OrderLineOption(
        groupName: json['groupName'] ?? '',
        optionName: json['optionName'] ?? '',
        price: _money(json['price']),
      );
}

class OrderTimelineEntry {
  final OrderStatus status;
  final String? message;
  final DateTime? at;

  OrderTimelineEntry({required this.status, this.message, this.at});

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) => OrderTimelineEntry(
        status: OrderStatus.fromName(json['status']),
        message: json['message'],
        at: _date(json['at']),
      );
}

/// Ações do restaurante sobre o pedido (gestor e cozinha)
enum OrderAction {
  accept('accept', 'Aceitar'),
  reject('reject', 'Recusar'),
  start('start', 'Iniciar preparo'),
  ready('ready', 'Pronto'),
  dispatch('dispatch', 'Saiu para entrega'),
  deliver('deliver', 'Entregue');

  final String path;
  final String label;
  const OrderAction(this.path, this.label);

  /// Próxima etapa natural a partir do status atual
  static OrderAction? nextFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return accept;
      case OrderStatus.CONFIRMED:
        return start;
      case OrderStatus.PREPARING:
        return ready;
      case OrderStatus.READY_FOR_PICKUP:
        return dispatch;
      case OrderStatus.OUT_FOR_DELIVERY:
        return deliver;
      default:
        return null;
    }
  }

  /// O restaurante ainda pode recusar/cancelar (antes de ficar pronto)
  static bool canReject(OrderStatus status) =>
      status == OrderStatus.PENDING || status == OrderStatus.CONFIRMED || status == OrderStatus.PREPARING;
}
