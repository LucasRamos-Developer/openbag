import '../models/cash/cash_report.dart';
import 'api_client.dart';

/// Caixa do restaurante: vendas do período e acerto com os entregadores
class RestaurantCashService {
  final ApiClient _api;

  RestaurantCashService(this._api);

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<CashReport> report(int restaurantId, {required DateTime from, required DateTime to}) async =>
      CashReport.fromJson(await _api.get('/restaurants/$restaurantId/cash', query: {'from': _date(from), 'to': _date(to)}));

  /// Fecha todas as entregas ainda não acertadas do entregador
  Future<Settlement> settle(int restaurantId, CourierCashLine line) async => Settlement.fromJson(
        await _api.post('/restaurants/$restaurantId/cash/settlements', data: {
          'deliveryPersonId': line.deliveryPersonId,
          'staffCourierId': line.staffCourierId,
        }),
      );
}
