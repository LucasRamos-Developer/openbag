import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/menu/menu.dart';
import '../models/store/store.dart';
import 'api_client.dart';

/// Estado e operações do painel do dono do restaurante (loja e cardápio)
class RestaurantPanelService extends ChangeNotifier {
  final ApiClient _api;

  RestaurantPanelService(this._api);

  List<RestaurantSummary> _restaurants = [];
  int? _selectedId;
  Store? _store;
  Menu? _menu;
  bool _isLoading = false;
  String? _error;

  List<RestaurantSummary> get restaurants => _restaurants;
  int? get selectedId => _selectedId;
  Store? get store => _store;
  Menu? get menu => _menu;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _base => '/restaurants/$_selectedId';
  String get _menuBase => '$_base/menu';

  /// Carrega os restaurantes do dono e seleciona o primeiro (ou o já selecionado)
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/restaurants/mine') as List;
      _restaurants = data.map((e) => RestaurantSummary.fromJson(e)).toList();
      if (_restaurants.isEmpty) {
        _selectedId = null;
      } else if (_selectedId == null || !_restaurants.any((r) => r.id == _selectedId)) {
        _selectedId = _restaurants.first.id;
      }
      if (_selectedId != null) {
        await Future.wait([_loadStore(), _loadMenu()]);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectRestaurant(int id) async {
    if (id == _selectedId) return;
    _selectedId = id;
    _store = null;
    _menu = null;
    notifyListeners();
    await load();
  }

  void clear() {
    _restaurants = [];
    _selectedId = null;
    _store = null;
    _menu = null;
    _error = null;
  }

  Future<void> _loadStore() async => _store = Store.fromJson(await _api.get('$_base/store'));

  Future<void> _loadMenu() async => _menu = Menu.fromJson(await _api.get(_menuBase));

  Future<void> refreshMenu() async {
    await _loadMenu();
    notifyListeners();
  }

  // ============= Loja =============

  Future<void> _storeAction(Future<dynamic> Function() request) async {
    _store = Store.fromJson(await request());
    notifyListeners();
  }

  Future<void> setOpen(bool open) => _storeAction(() => _api.put('$_base/open', data: {'open': open}));

  Future<void> pause(int minutes) => _storeAction(() => _api.post('$_base/pause', data: {'minutes': minutes}));

  Future<void> resume() => _storeAction(() => _api.delete('$_base/pause'));

  Future<void> updateSettings(Map<String, dynamic> settings) =>
      _storeAction(() => _api.put('$_base/settings', data: settings));

  /// Nome, descrição, telefone, categorias e faixa de preço (o slug não muda)
  Future<void> updateProfile(Map<String, dynamic> profile) =>
      _storeAction(() => _api.put('$_base/profile', data: profile));

  Future<void> updateAddress(Map<String, dynamic> address) =>
      _storeAction(() => _api.put('$_base/address', data: address));

  Future<void> updateOpeningHours(List<OpeningHour> hours) => _storeAction(
      () => _api.put('$_base/opening-hours', data: {'hours': hours.map((h) => h.toJson()).toList()}));

  /// Tema, cor da marca (null = cor do tema) e slogan da página pública
  Future<void> updateAppearance({required String themePreset, String? brandColor, String? slogan}) => _storeAction(
      () => _api.put('$_base/appearance', data: {'themePreset': themePreset, 'brandColor': brandColor, 'slogan': slogan}));

  /// Envia o logo ou o banner (a resposta não é a loja, então recarrega a loja em seguida)
  Future<void> uploadStoreImage(StoreImage kind, XFile file) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name),
    });
    await _api.post('$_base/upload-${kind.name}', data: form);
    await _loadStore();
    notifyListeners();
  }

  Future<void> removeStoreImage(StoreImage kind) async {
    await _api.delete('$_base/${kind.name}');
    await _loadStore();
    notifyListeners();
  }

  // ============= Cardápio =============

  /// Executa uma alteração no cardápio e recarrega o cardápio inteiro (posições e contagens mudam juntas)
  Future<T> _menuAction<T>(Future<T> Function() action) async {
    final result = await action();
    await refreshMenu();
    return result;
  }

  Future<void> createSection(String name, {String? description, String? icon}) => _menuAction(
      () => _api.post('$_menuBase/sections', data: {'name': name, 'description': description, 'icon': icon}));

  Future<void> updateSection(MenuSection section,
          {required String name, String? description, String? icon, bool? active}) =>
      _menuAction(() => _api.put('$_menuBase/sections/${section.id}',
          data: {'name': name, 'description': description, 'icon': icon, 'active': active}));

  Future<void> deleteSection(int sectionId) => _menuAction(() => _api.delete('$_menuBase/sections/$sectionId'));

  /// Reordena localmente na hora (resposta imediata ao arrastar) e confirma no servidor
  Future<void> reorderSections(List<int> ids) async {
    final byId = {for (final s in _menu!.sections) s.id: s};
    _menu = Menu(
      restaurantId: _menu!.restaurantId,
      sections: ids.map((id) => byId[id]!).toList(),
      unsectionedItems: _menu!.unsectionedItems,
    );
    notifyListeners();
    await _menuAction(() => _api.put('$_menuBase/sections/reorder', data: {'ids': ids}));
  }

  Future<void> reorderItems(int sectionId, List<int> ids) =>
      _menuAction(() => _api.put('$_menuBase/sections/$sectionId/items/reorder', data: {'ids': ids}));

  Future<MenuItem> saveItem(int? itemId, Map<String, dynamic> body) => _menuAction(() async {
        final data = itemId == null
            ? await _api.post('$_menuBase/items', data: body)
            : await _api.put('$_menuBase/items/$itemId', data: body);
        return MenuItem.fromJson(data);
      });

  Future<void> deleteItem(int itemId) => _menuAction(() => _api.delete('$_menuBase/items/$itemId'));

  Future<void> setItemAvailability(int itemId, bool available) => _menuAction(
      () => _api.patch('$_menuBase/items/$itemId/availability', data: {'available': available}));

  Future<MenuItem> uploadItemImage(int itemId, XFile file) => _menuAction(() async {
        final form = FormData.fromMap({
          'file': MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name),
        });
        return MenuItem.fromJson(await _api.post('$_menuBase/items/$itemId/image', data: form));
      });

  Future<void> removeItemImage(int itemId) => _menuAction(() => _api.delete('$_menuBase/items/$itemId/image'));

  Future<void> saveCustomizationGroup(int itemId, CustomizationGroup group) => _menuAction(() => group.id == null
      ? _api.post('$_menuBase/items/$itemId/customization-groups', data: group.toRequestJson())
      : _api.put('$_menuBase/customization-groups/${group.id}', data: group.toRequestJson()));

  Future<void> deleteCustomizationGroup(int groupId) =>
      _menuAction(() => _api.delete('$_menuBase/customization-groups/$groupId'));

  Future<Combo> saveCombo(int? comboId, Map<String, dynamic> body) => _menuAction(() async {
        final data = comboId == null
            ? await _api.post('$_menuBase/combos', data: body)
            : await _api.put('$_menuBase/combos/$comboId', data: body);
        return Combo.fromJson(data);
      });

  Future<void> deleteCombo(int comboId) => _menuAction(() => _api.delete('$_menuBase/combos/$comboId'));

  Future<void> setComboAvailability(int comboId, bool available) => _menuAction(
      () => _api.patch('$_menuBase/combos/$comboId/availability', data: {'available': available}));

  Future<void> uploadComboImage(int comboId, XFile file) => _menuAction(() async {
        final form = FormData.fromMap({
          'file': MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name),
        });
        return _api.post('$_menuBase/combos/$comboId/image', data: form);
      });
}

/// Imagens da loja; o nome casa com as rotas do backend (upload-logo, /logo, upload-banner, /banner)
enum StoreImage { logo, banner }
