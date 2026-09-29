import '../models/order/order.dart';
import 'api_client.dart';
import 'idempotency_key.dart';

/// Pedidos do cliente
class OrderService {
  final ApiClient _api;

  OrderService(this._api);

  final _createKey = IdempotencyKey();

  /// Finaliza o pedido. Se a rede cair no meio, tocar de novo não cria um segundo pedido.
  Future<Order> createOrder(Map<String, dynamic> body) => _createKey.run(
      body, (key) async => Order.fromJson(await _api.post('/orders', data: body, idempotencyKey: key)));

  /// Taxa de entrega para o endereço do checkout (a loja pode cobrar pela distância)
  Future<DeliveryQuote> quoteDelivery(int restaurantId, Map<String, dynamic> address) async =>
      DeliveryQuote.fromJson(await _api.post('/orders/delivery-quote', data: {'restaurantId': restaurantId, ...address}));

  Future<List<Order>> fetchMyOrders({int page = 0}) async {
    final data = await _api.get('/orders/mine', query: {'page': page, 'size': 30});
    return (data['content'] as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> fetchOrder(int id) async => Order.fromJson(await _api.get('/orders/$id'));

  Future<Order> cancelOrder(int id) async => Order.fromJson(await _api.post('/orders/$id/cancel'));
}

/// Taxa para um endereço; [distanceKm] nulo = o endereço não foi achado no mapa (vale o "a partir de")
class DeliveryQuote {
  final double fee;
  final double? distanceKm;
  final bool byDistance;

  const DeliveryQuote({required this.fee, this.distanceKm, required this.byDistance});

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) => DeliveryQuote(
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        byDistance: json['byDistance'] ?? false,
      );
}
