import '../models/order/order.dart';
import 'api_client.dart';

/// Pedidos do cliente
class OrderService {
  final ApiClient _api;

  OrderService(this._api);

  Future<Order> createOrder(Map<String, dynamic> body) async => Order.fromJson(await _api.post('/orders', data: body));

  Future<List<Order>> fetchMyOrders({int page = 0}) async {
    final data = await _api.get('/orders/mine', query: {'page': page, 'size': 30});
    return (data['content'] as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> fetchOrder(int id) async => Order.fromJson(await _api.get('/orders/$id'));

  Future<Order> cancelOrder(int id) async => Order.fromJson(await _api.post('/orders/$id/cancel'));
}
