import '../models/cash/cash_report.dart';
import '../utils/formatters.dart';
import 'api_client.dart';
import 'idempotency_key.dart';

/// Caixa do restaurante: vendas do período e acerto com os entregadores
class RestaurantCashService {
  final ApiClient _api;

  RestaurantCashService(this._api);

  final _settleKey = IdempotencyKey();

  Future<CashReport> report(int restaurantId, {required DateTime from, required DateTime to}) async =>
      CashReport.fromJson(await _api.get('/restaurants/$restaurantId/cash', query: {'from': apiDate(from), 'to': apiDate(to)}));

  /// Fecha todas as entregas ainda não acertadas do entregador
  Future<Settlement> settle(int restaurantId, CourierCashLine line) {
    final body = {'deliveryPersonId': line.deliveryPersonId, 'staffCourierId': line.staffCourierId};
    return _settleKey.run(
        {'restaurantId': restaurantId, ...body},
        (key) async => Settlement.fromJson(
            await _api.post('/restaurants/$restaurantId/cash/settlements', data: body, idempotencyKey: key)));
  }
}
