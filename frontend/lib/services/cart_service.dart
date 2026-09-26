import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Complemento escolhido em uma linha do carrinho
class CartOption {
  final int id;
  final String groupName;
  final String name;
  final double price;

  const CartOption({required this.id, required this.groupName, required this.name, required this.price});

  Map<String, dynamic> toJson() => {'id': id, 'groupName': groupName, 'name': name, 'price': price};

  factory CartOption.fromJson(Map<String, dynamic> json) => CartOption(
        id: json['id'],
        groupName: json['groupName'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] as num).toDouble(),
      );
}

/// Linha do carrinho: um item (com complementos e observação) ou um combo
class CartLine {
  final int? productId;
  final int? comboId;
  final String name;
  final String? imageUrl;

  /// Preço unitário já com complementos (o servidor recalcula ao fechar o pedido)
  final double unitPrice;
  int quantity;
  final String? notes;
  final List<CartOption> options;

  CartLine({
    this.productId,
    this.comboId,
    required this.name,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.notes,
    this.options = const [],
  });

  double get totalPrice => unitPrice * quantity;

  /// Mesma escolha = mesma linha (soma quantidade em vez de duplicar)
  String get key {
    final optionIds = options.map((o) => o.id).toList()..sort();
    return '${productId ?? ''}|${comboId ?? ''}|${optionIds.join(',')}|${notes ?? ''}';
  }

  String get optionsSummary => options.map((o) => o.name).join(', ');

  Map<String, dynamic> toOrderItem() => {
        if (productId != null) 'productId': productId,
        if (comboId != null) 'comboId': comboId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
        'optionIds': options.map((o) => o.id).toList(),
      };

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'comboId': comboId,
        'name': name,
        'imageUrl': imageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'notes': notes,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        productId: json['productId'],
        comboId: json['comboId'],
        name: json['name'] ?? '',
        imageUrl: json['imageUrl'],
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] ?? 1,
        notes: json['notes'],
        options: (json['options'] as List? ?? []).map((e) => CartOption.fromJson(e)).toList(),
      );
}

/// Restaurante do carrinho (o carrinho tem itens de um restaurante só)
class CartRestaurant {
  final int id;
  final String slug;
  final String name;
  final String? logoUrl;
  final double deliveryFee;
  final double minimumOrder;

  const CartRestaurant({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    required this.deliveryFee,
    required this.minimumOrder,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
        'logoUrl': logoUrl,
        'deliveryFee': deliveryFee,
        'minimumOrder': minimumOrder,
      };

  factory CartRestaurant.fromJson(Map<String, dynamic> json) => CartRestaurant(
        id: json['id'],
        slug: json['slug'] ?? '',
        name: json['name'] ?? '',
        logoUrl: json['logoUrl'],
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        minimumOrder: (json['minimumOrder'] as num).toDouble(),
      );
}

/// Tentativa de adicionar item de outro restaurante
class CartConflictException implements Exception {
  final String currentRestaurant;
  CartConflictException(this.currentRestaurant);
}

/// Carrinho do cliente, salvo no aparelho (sobrevive a recarregar a página)
class CartService extends ChangeNotifier {
  static const _storageKey = 'cart_v2';

  final List<CartLine> _lines = [];
  CartRestaurant? _restaurant;

  CartService() {
    _restore();
  }

  List<CartLine> get lines => List.unmodifiable(_lines);
  CartRestaurant? get restaurant => _restaurant;
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.fold(0, (sum, l) => sum + l.quantity);
  double get subtotal => _lines.fold(0.0, (sum, l) => sum + l.totalPrice);
  double get deliveryFee => _restaurant?.deliveryFee ?? 0;
  double get total => subtotal + deliveryFee;

  /// Quanto falta para o pedido mínimo (0 se já atingiu)
  double get missingForMinimum {
    final minimum = _restaurant?.minimumOrder ?? 0;
    return subtotal >= minimum ? 0 : minimum - subtotal;
  }

  /// Adiciona uma linha. Se o carrinho for de outro restaurante, lança [CartConflictException]
  /// (a menos que [replace] seja true, que esvazia o carrinho antes)
  void add(CartLine line, CartRestaurant restaurant, {bool replace = false}) {
    if (_restaurant != null && _restaurant!.id != restaurant.id && _lines.isNotEmpty) {
      if (!replace) throw CartConflictException(_restaurant!.name);
      _lines.clear();
    }
    _restaurant = restaurant;

    final existing = _lines.where((l) => l.key == line.key).firstOrNull;
    if (existing != null) {
      existing.quantity += line.quantity;
    } else {
      _lines.add(line);
    }
    _changed();
  }

  void updateQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      remove(line);
      return;
    }
    line.quantity = quantity;
    _changed();
  }

  void remove(CartLine line) {
    _lines.remove(line);
    if (_lines.isEmpty) _restaurant = null;
    _changed();
  }

  void clear() {
    _lines.clear();
    _restaurant = null;
    _changed();
  }

  List<Map<String, dynamic>> toOrderItems() => _lines.map((l) => l.toOrderItem()).toList();

  void _changed() {
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lines.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(_storageKey, json.encode({
      'restaurant': _restaurant?.toJson(),
      'lines': _lines.map((l) => l.toJson()).toList(),
    }));
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final data = json.decode(raw) as Map<String, dynamic>;
      _restaurant = data['restaurant'] != null ? CartRestaurant.fromJson(data['restaurant']) : null;
      _lines
        ..clear()
        ..addAll((data['lines'] as List).map((e) => CartLine.fromJson(e)));
      notifyListeners();
    } catch (_) {
      // Carrinho salvo em formato antigo ou corrompido: começa vazio
    }
  }
}
