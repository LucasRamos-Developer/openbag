import 'package:flutter/foundation.dart';
import '../models/association/association_summary.dart';
import '../models/delivery/courier_link.dart';
import '../models/delivery/courier_options.dart';
import '../models/delivery/staff_courier.dart';
import '../models/delivery/delivery_rate.dart';
import '../models/delivery/restaurant_delivery_settings.dart';
import 'api_client.dart';
import 'association_directory.dart' as association_directory;

/// Entrega do restaurante selecionado: política, parceiras, fixos, equipe própria e quem leva cada pedido
class RestaurantDeliveryService extends ChangeNotifier {
  final ApiClient _api;

  RestaurantDeliveryService(this._api);

  int? _restaurantId;
  RestaurantDeliverySettings? _settings;
  List<CourierLink> _links = [];
  List<StaffCourier> _staff = [];
  bool _isLoading = false;
  String? _error;

  RestaurantDeliverySettings? get settings => _settings;
  List<CourierLink> get links => _links;
  List<StaffCourier> get staff => _staff;
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
      await Future.wait([_loadSettings(), refreshLinks(notify: false), _loadStaff()]);
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
    _staff = [];
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
    bool? passesDeliveryFee,
    int? courierNoShowMinutes,
  }) async {
    _settings = RestaurantDeliverySettings.fromJson(await _api.put('$_base/settings', data: {
      'courierPolicy': policy.name,
      'fallbackToOpen': fallbackToOpen,
      'coversDeliveryDifference': coversDeliveryDifference,
      if (passesDeliveryFee != null) 'deliveryFeeMode': passesDeliveryFee ? 'PASS_THROUGH' : 'ASSUME',
      if (courierNoShowMinutes != null) 'courierNoShowMinutes': courierNoShowMinutes,
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

  /// accept, decline, end, rate-accept, rate-decline ou rate-cancel ([PartnershipAction])
  Future<void> partnershipAction(int partnershipId, String action) async {
    _settings = RestaurantDeliverySettings.fromJson(await _api.post('$_base/partners/$partnershipId/$action'));
    notifyListeners();
  }

  /// Propõe uma tabela especial à associação; [rate] nulo = voltar à tabela padrão
  Future<void> proposeRate(int partnershipId, DeliveryRate? rate) async {
    _settings = RestaurantDeliverySettings.fromJson(await _api.post('$_base/partners/$partnershipId/rate-proposal',
        data: {'rate': rate?.toJson(), 'toDefault': rate == null}));
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

  // ============= Quem leva cada pedido =============

  // Recebem o restaurante do pedido: a ficha pode abrir antes de a aba Entregadores carregar o restaurante
  String _orderBase(int restaurantId, int orderId) => '/restaurants/$restaurantId/delivery/orders/$orderId';

  Future<CourierOptions> courierOptions(int restaurantId, int orderId) async =>
      CourierOptions.fromJson(await _api.get('${_orderBase(restaurantId, orderId)}/courier-options'));

  /// Atribui direto (sem oferta) a um entregador do app ou da equipe própria
  Future<void> assignCourier(int restaurantId, int orderId, CourierOption option) =>
      _api.put('${_orderBase(restaurantId, orderId)}/courier', data: {
        'deliveryPersonId': option.deliveryPersonId,
        'staffCourierId': option.staffCourierId,
      });

  /// Tira o entregador; o pedido volta a procurar outro
  Future<void> unassignCourier(int restaurantId, int orderId) => _api.delete('${_orderBase(restaurantId, orderId)}/courier');

  // ============= Equipe própria =============

  Future<void> _loadStaff() async =>
      _staff = [for (final s in await _api.get('$_base/staff') as List) StaffCourier.fromJson(s)];

  Future<void> saveStaff({int? id, required String name, String? phone, double? feePerDelivery}) async {
    final body = {'name': name, 'phone': phone, 'feePerDelivery': feePerDelivery};
    if (id == null) {
      await _api.post('$_base/staff', data: body);
    } else {
      await _api.put('$_base/staff/$id', data: body);
    }
    await _loadStaff();
    notifyListeners();
  }

  Future<void> removeStaff(int id) async {
    await _api.delete('$_base/staff/$id');
    await _loadStaff();
    notifyListeners();
  }

  Future<void> _afterLinkChange() async {
    await Future.wait([_loadSettings(), refreshLinks(notify: false)]);
    notifyListeners();
  }
}
