import 'package:flutter/foundation.dart';
import '../models/association/association_summary.dart';
import '../models/delivery/courier_link.dart';
import '../models/delivery/restaurant_delivery_settings.dart';
import 'api_client.dart';
import 'association_directory.dart' as association_directory;

/// Regras de entrega do restaurante selecionado: política, parceiras e entregadores fixos
class RestaurantDeliveryService extends ChangeNotifier {
  final ApiClient _api;

  RestaurantDeliveryService(this._api);

  int? _restaurantId;
  RestaurantDeliverySettings? _settings;
  List<CourierLink> _links = [];
  bool _isLoading = false;
  String? _error;

  RestaurantDeliverySettings? get settings => _settings;
  List<CourierLink> get links => _links;
  List<CourierLink> get pendingLinks => _links.where((l) => l.isPending).toList();
  List<CourierLink> get activeLinks => _links.where((l) => l.isActive).toList();
  List<CourierLink> get checkedIn => _links.where((l) => l.isActive && l.checkedIn).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _base => '/restaurants/$_restaurantId/delivery';

  Future<void> load(int restaurantId) async {
    _restaurantId = restaurantId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadSettings(), refreshLinks(notify: false)]);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _restaurantId = null;
    _settings = null;
    _links = [];
    _error = null;
  }

  Future<void> _loadSettings() async => _settings = RestaurantDeliverySettings.fromJson(await _api.get('$_base/settings'));

  Future<void> refreshLinks({bool notify = true}) async {
    if (_restaurantId == null) return;
    _links = [for (final l in await _api.get('$_base/couriers') as List) CourierLink.fromJson(l)];
    if (notify) notifyListeners();
  }

  // ============= Regras =============

  Future<void> updateSettings({
    required CourierPolicy policy,
    required bool fallbackToOpen,
    required bool coversDeliveryDifference,
  }) async {
    _settings = RestaurantDeliverySettings.fromJson(await _api.put('$_base/settings', data: {
      'courierPolicy': policy.name,
      'fallbackToOpen': fallbackToOpen,
      'coversDeliveryDifference': coversDeliveryDifference,
    }));
    notifyListeners();
  }

  Future<List<AssociationSummary>> fetchActiveAssociations() => association_directory.fetchActiveAssociations(_api);

  Future<void> addPartner(int organizationId) async {
    _settings = RestaurantDeliverySettings.fromJson(
        await _api.post('$_base/partners', data: {'organizationId': organizationId}));
    notifyListeners();
  }

  Future<void> removePartner(int organizationId) async {
    _settings = RestaurantDeliverySettings.fromJson(await _api.delete('$_base/partners/$organizationId'));
    notifyListeners();
  }

  // ============= Fixos =============

  Future<void> inviteCourier(String profileLink) async {
    await _api.post('$_base/couriers/invite', data: {'target': profileLink});
    await _afterLinkChange();
  }

  /// approve, reject ou end
  Future<void> linkAction(CourierLink link, String action) async {
    await _api.post('$_base/couriers/${link.id}/$action');
    await _afterLinkChange();
  }

  /// Oferece o pedido a um fixo em check-in
  Future<void> assignOrder(int orderId, int deliveryPersonId) async {
    await _api.post('$_base/orders/$orderId/assign/$deliveryPersonId');
  }

  Future<void> _afterLinkChange() async {
    await Future.wait([_loadSettings(), refreshLinks(notify: false)]);
    notifyListeners();
  }
}
