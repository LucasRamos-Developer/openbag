import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';
import 'auth_service.dart';

class RestaurantService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8080/api';
  
  List<Restaurant> _restaurants = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Restaurant> get restaurants => _restaurants;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/public'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Erro ao carregar restaurantes';
      }
    } catch (e) {
      _error = 'Erro de conexão';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/public'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _categories = data.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
    }
    
    notifyListeners();
  }

  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Restaurant.fromJson(data);
      }
    } catch (e) {
      debugPrint('Erro ao carregar restaurante: $e');
    }
    
    return null;
  }

  List<Restaurant> searchRestaurants(String query) {
    if (query.isEmpty) return _restaurants;
    
    return _restaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(query.toLowerCase()) ||
             restaurant.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<Restaurant> getRestaurantsByCategory(int categoryId) {
    return _restaurants.where((restaurant) {
      return restaurant.categories.any((cat) => cat.id == categoryId);
    }).toList();
  }

  List<Restaurant> getTopRatedRestaurants() {
    final sorted = List<Restaurant>.from(_restaurants);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(10).toList();
  }
}
