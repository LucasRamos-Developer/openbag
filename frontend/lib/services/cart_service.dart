import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? observations;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.observations,
  });

  double get totalPrice => product.currentPrice * quantity;
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? _selectedRestaurantId;

  List<CartItem> get items => _items;
  int? get selectedRestaurantId => _selectedRestaurantId;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addItem(Product product, {int quantity = 1, String? observations}) {
    // Verifica se é do mesmo restaurante
    if (_selectedRestaurantId != null && _selectedRestaurantId != product.restaurantId) {
      throw Exception('Você só pode adicionar itens do mesmo restaurante');
    }

    _selectedRestaurantId = product.restaurantId;

    // Verifica se o produto já está no carrinho
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      if (observations != null) {
        _items[existingIndex].observations = observations;
      }
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        observations: observations,
      ));
    }
    
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    
    if (_items.isEmpty) {
      _selectedRestaurantId = null;
    }
    
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _selectedRestaurantId = null;
    notifyListeners();
  }

  CartItem? getItem(int productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }
}
