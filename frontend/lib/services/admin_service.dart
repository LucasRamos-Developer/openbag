import '../core/ui/ui.dart';
import '../models/admin/admin_rows.dart';
import '../models/order/order.dart';
import 'api_client.dart';

/// Painel do super admin: números e listas somente leitura da plataforma
class AdminService {
  static const pageSize = 20;

  final ApiClient _api;

  AdminService(this._api);

  Future<AdminOverview> overview() async => AdminOverview.fromJson(await _api.get('/admin/overview'));

  Future<AppPage<T>> _page<T>(String path, T Function(Map<String, dynamic>) fromJson, Map<String, dynamic> query) async {
    final data = await _api.get(path, query: {...query, 'size': pageSize});
    return AppPage.fromJson(data, fromJson);
  }

  Future<AppPage<AdminRestaurantRow>> restaurants({String query = '', int page = 0}) =>
      _page('/admin/restaurants', AdminRestaurantRow.fromJson, {'q': query, 'page': page});

  Future<AppPage<AdminCourierRow>> couriers({String query = '', int page = 0}) =>
      _page('/admin/couriers', AdminCourierRow.fromJson, {'q': query, 'page': page});

  Future<AppPage<AdminUserRow>> users({String query = '', int page = 0}) =>
      _page('/admin/users', AdminUserRow.fromJson, {'q': query, 'page': page});

  Future<AppPage<AdminOrderRow>> orders({OrderStatus? status, int page = 0}) =>
      _page('/admin/orders', AdminOrderRow.fromJson, {'status': status?.name, 'page': page});
}
