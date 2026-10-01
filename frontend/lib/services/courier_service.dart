import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/association/association_report.dart';
import '../models/association/association_summary.dart';
import '../models/association/member.dart';
import '../models/courier/courier_earnings.dart';
import '../models/courier/courier_profile.dart';
import '../models/delivery/courier_link.dart';
import '../models/courier/courier_public.dart';
import '../models/courier/social_link.dart';
import '../models/courier/vehicle.dart';
import '../utils/formatters.dart';
import 'api_client.dart';
import 'association_directory.dart' as association_directory;

/// Estado e operações do painel do entregador: perfil, foto e veículos
class CourierService extends ChangeNotifier {
  final ApiClient _api;

  CourierService(this._api);

  static const _base = '/me/courier';

  CourierProfile? _profile;
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  CourierProfile? get profile => _profile;
  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carrega perfil e veículos do entregador logado
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([_api.get(_base), _api.get('$_base/vehicles')]);
      _profile = CourierProfile.fromJson(results[0]);
      _vehicles = _parseVehicles(results[1]);
      _links = [for (final l in await _api.get('$_base/restaurants') as List) CourierLink.fromJson(l)];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _links = [];
    _profile = null;
    _vehicles = [];
    _error = null;
  }

  // ============= Perfil =============

  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? bio,
    required bool showWorkHistory,
    required List<SocialLink> socialLinks,
  }) async {
    _profile = CourierProfile.fromJson(await _api.put(_base, data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'showWorkHistory': showWorkHistory,
      'socialLinks': [for (final link in socialLinks) link.toJson()],
    }));
    notifyListeners();
  }

  Future<void> updatePhoto(XFile file) async {
    _profile = CourierProfile.fromJson(await _api.post('$_base/photo', data: await _form(file)));
    notifyListeners();
  }

  // ============= Veículos =============

  Future<Vehicle> saveVehicle(Map<String, dynamic> body, {int? id}) async {
    final data = id == null
        ? await _api.post('$_base/vehicles', data: body)
        : await _api.put('$_base/vehicles/$id', data: body);
    final vehicle = Vehicle.fromJson(data);
    await _reloadVehiclesAndProfile();
    return vehicle;
  }

  /// Custos do veículo para o resultado estimado (vazio apaga)
  Future<void> updateVehicleCosts(int id, {
    double? fuelConsumptionKmPerLiter,
    double? fuelPricePerLiter,
    double? maintenancePerKm,
    double? depreciationPerKm,
  }) async {
    final updated = Vehicle.fromJson(await _api.put('$_base/vehicles/$id/costs', data: {
      'fuelConsumptionKmPerLiter': fuelConsumptionKmPerLiter,
      'fuelPricePerLiter': fuelPricePerLiter,
      'maintenancePerKm': maintenancePerKm,
      'depreciationPerKm': depreciationPerKm,
    }));
    _vehicles = [for (final v in _vehicles) v.id == id ? updated : v];
    notifyListeners();
  }

  Future<void> updateVehiclePhoto(int id, XFile file) async {
    await _api.post('$_base/vehicles/$id/photo', data: await _form(file));
    await _reloadVehiclesAndProfile();
  }

  Future<void> activateVehicle(int id) async {
    _vehicles = _parseVehicles(await _api.post('$_base/vehicles/$id/activate'));
    await _reloadProfile();
  }

  Future<void> removeVehicle(int id) async {
    _vehicles = _parseVehicles(await _api.delete('$_base/vehicles/$id'));
    await _reloadProfile();
  }

  // ============= Associação =============

  Future<List<AssociationSummary>> fetchActiveAssociations() => association_directory.fetchActiveAssociations(_api);

  /// Associação do código de convite (erro se o código for inválido ou expirado)
  Future<AssociationSummary> validateInvite(String code) async {
    return AssociationSummary.fromJson(await _api.get('/public/associations/invites/${code.trim().toUpperCase()}'));
  }

  /// Auto-cadastro do entregador (público). Com convite já entra ativo; escolhendo a associação fica pendente.
  Future<Member> register(Map<String, dynamic> body) async {
    return Member.fromJson(await _api.post('/auth/register/delivery-person', data: body));
  }

  Future<void> requestToJoin(AssociationChoice choice) async {
    await _api.post('/me/association/request', data: choice.toJson());
    await _reloadProfile();
  }

  Future<void> leaveAssociation({String? reason}) async {
    await _api.post('/me/association/leave', data: reason != null && reason.isNotEmpty ? {'reason': reason} : null);
    await _reloadProfile();
  }

  // ============= Restaurantes (fixo) =============

  List<CourierLink> _links = [];
  List<CourierLink> get links => _links;
  List<CourierLink> get activeLinks => _links.where((l) => l.isActive).toList();

  Future<void> loadLinks() async {
    _links = [for (final l in await _api.get('$_base/restaurants') as List) CourierLink.fromJson(l)];
    notifyListeners();
  }

  /// Pede para ser fixo pelo link (ou slug) da página do restaurante
  Future<void> requestLink(String restaurantLink) async {
    await _api.post('$_base/restaurants/link', data: {'target': restaurantLink});
    await loadLinks();
  }

  /// accept, decline ou end
  Future<void> linkAction(CourierLink link, String action) async {
    await _api.post('$_base/restaurants/${link.id}/$action');
    await loadLinks();
  }

  // ============= Ganhos e histórico =============

  Future<CourierEarnings> fetchEarnings({required DateTime from, required DateTime to}) async {
    return CourierEarnings.fromJson(await _api.get('$_base/earnings', query: {'from': apiDate(from), 'to': apiDate(to)}));
  }

  /// Resumo da associação no período (total e por loja) com a parte do entregador
  Future<AssociationReport> fetchAssociationReport({required DateTime from, required DateTime to}) async =>
      AssociationReport.fromJson(
          await _api.get('/me/association/report', query: {'from': apiDate(from), 'to': apiDate(to)}));

  Future<WorkHistory> fetchHistory() async => WorkHistory.fromJson(await _api.get('$_base/history'));

  // ============= Público =============

  /// Perfil público (não exige login)
  Future<CourierPublic> fetchPublicProfile(String slug) async {
    return CourierPublic.fromJson(await _api.get('/public/couriers/$slug'));
  }

  // ============= Auxiliares =============

  Future<void> _reloadVehiclesAndProfile() async {
    _vehicles = _parseVehicles(await _api.get('$_base/vehicles'));
    await _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    _profile = CourierProfile.fromJson(await _api.get(_base));
    notifyListeners();
  }

  static List<Vehicle> _parseVehicles(dynamic data) => [for (final v in data as List) Vehicle.fromJson(v)];

  static Future<FormData> _form(XFile file) async {
    final bytes = await file.readAsBytes();
    return FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: file.name)});
  }
}

/// Associação escolhida pelo entregador: pelo código de convite (entra ativo) ou pela lista (fica pendente)
class AssociationChoice {
  final int? organizationId;
  final String? inviteCode;
  final AssociationSummary association;

  const AssociationChoice.invite(String code, this.association)
      : inviteCode = code,
        organizationId = null;

  AssociationChoice.request(this.association)
      : organizationId = association.id,
        inviteCode = null;

  bool get isInvite => inviteCode != null;

  Map<String, dynamic> toJson() => {
        if (organizationId != null) 'organizationId': organizationId,
        if (inviteCode != null) 'inviteCode': inviteCode!.trim().toUpperCase(),
      };
}
