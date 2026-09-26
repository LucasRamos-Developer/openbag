import 'package:flutter/foundation.dart';
import '../models/menu/menu.dart';
import '../models/restaurant.dart';
import 'api_client.dart';

/// Vitrine de restaurantes (endpoints públicos, sem login)
class RestaurantService extends ChangeNotifier {
  final ApiClient _api;

  RestaurantService(this._api);

  List<Restaurant> _restaurants = [];
  bool _isLoading = false;
  String? _error;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/public/restaurants', query: {'size': 50});
      _restaurants = (data['content'] as List).map((e) => Restaurant.fromJson(e)).toList();
      // Abertos primeiro
      _restaurants.sort((a, b) => (b.openNow ? 1 : 0) - (a.openNow ? 1 : 0));
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Página do restaurante (aceita slug ou id)
  Future<Restaurant> fetchRestaurant(String slugOrId) async =>
      Restaurant.fromJson(await _api.get('/public/restaurants/$slugOrId'));

  /// Cardápio público: só seções visíveis e itens disponíveis
  Future<Menu> fetchMenu(String slugOrId) async => Menu.fromJson(await _api.get('/public/restaurants/$slugOrId/menu'));
}
