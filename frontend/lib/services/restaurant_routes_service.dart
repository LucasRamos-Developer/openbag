import '../models/delivery/courier_options.dart';
import '../models/routes/routes_board.dart';
import 'api_client.dart';

/// Painel de rotas do restaurante: acompanhar e corrigir o que o planejador montou
class RestaurantRoutesService {
  final ApiClient _api;

  RestaurantRoutesService(this._api);

  String _base(int restaurantId) => '/restaurants/$restaurantId/routes';

  Future<RoutesBoard> board(int restaurantId) async => RoutesBoard.fromJson(await _api.get(_base(restaurantId)));

  /// Junta pedidos numa rota (sai já, procurando entregador)
  Future<void> merge(int restaurantId, List<int> orderIds) =>
      _api.post(_base(restaurantId), data: {'orderIds': orderIds});

  /// Chama o entregador agora: da rota ou de um pedido sozinho
  Future<void> dispatchNow(int restaurantId, RouteCard card) => card.isRoute
      ? _api.post('${_base(restaurantId)}/${card.routeId}/dispatch')
      : _api.post('${_base(restaurantId)}/orders/${card.lead.orderId}/dispatch');

  /// Separa um pedido da rota: sai sozinho e não volta a ser agrupado
  Future<void> separate(int restaurantId, int routeId, int orderId) =>
      _api.delete('${_base(restaurantId)}/$routeId/orders/$orderId');

  Future<void> assign(int restaurantId, int routeId, CourierOption option) =>
      _api.put('${_base(restaurantId)}/$routeId/courier', data: {
        'deliveryPersonId': option.deliveryPersonId,
        'staffCourierId': option.staffCourierId,
      });

  Future<DeliveryRouteSettings> updateSettings(int restaurantId, DeliveryRouteSettings settings) async =>
      DeliveryRouteSettings.fromJson(await _api.put('${_base(restaurantId)}/settings', data: settings.toJson()));
}
