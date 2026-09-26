double _money(dynamic value) => (value as num?)?.toDouble() ?? 0;

/// Cardápio completo do restaurante
class Menu {
  final int restaurantId;
  final List<MenuSection> sections;

  /// Itens antigos ainda sem seção (visão do dono)
  final List<MenuItem> unsectionedItems;

  Menu({required this.restaurantId, required this.sections, required this.unsectionedItems});

  /// Todos os itens (para montar combos)
  List<MenuItem> get allItems => [...sections.expand((s) => s.items), ...unsectionedItems];

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        restaurantId: json['restaurantId'],
        sections: (json['sections'] as List? ?? []).map((e) => MenuSection.fromJson(e)).toList(),
        unsectionedItems: (json['unsectionedItems'] as List? ?? []).map((e) => MenuItem.fromJson(e)).toList(),
      );
}

class MenuSection {
  final int id;
  final String name;
  final String? description;
  final int position;
  final bool active;
  final List<MenuItem> items;
  final List<Combo> combos;

  MenuSection({
    required this.id,
    required this.name,
    this.description,
    required this.position,
    required this.active,
    required this.items,
    required this.combos,
  });

  factory MenuSection.fromJson(Map<String, dynamic> json) => MenuSection(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'],
        position: json['position'] ?? 0,
        active: json['active'] ?? true,
        items: (json['items'] as List? ?? []).map((e) => MenuItem.fromJson(e)).toList(),
        combos: (json['combos'] as List? ?? []).map((e) => Combo.fromJson(e)).toList(),
      );
}

class MenuItem {
  final int id;
  final int? sectionId;
  final String name;
  final String? description;
  final double price;
  final double? promotionalPrice;
  final double currentPrice;
  final String? imageUrl;
  final bool available;
  final bool active;
  final int? preparationTime;
  final List<CustomizationGroup> customizationGroups;

  MenuItem({
    required this.id,
    this.sectionId,
    required this.name,
    this.description,
    required this.price,
    this.promotionalPrice,
    required this.currentPrice,
    this.imageUrl,
    required this.available,
    required this.active,
    this.preparationTime,
    required this.customizationGroups,
  });

  bool get hasPromotion => promotionalPrice != null && promotionalPrice! < price;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'],
        sectionId: json['sectionId'],
        name: json['name'] ?? '',
        description: json['description'],
        price: _money(json['price']),
        promotionalPrice: json['promotionalPrice'] != null ? _money(json['promotionalPrice']) : null,
        currentPrice: _money(json['currentPrice'] ?? json['price']),
        imageUrl: json['imageUrl'],
        available: json['available'] ?? true,
        active: json['active'] ?? true,
        preparationTime: json['preparationTime'],
        customizationGroups:
            (json['customizationGroups'] as List? ?? []).map((e) => CustomizationGroup.fromJson(e)).toList(),
      );
}

/// Grupo de complementos (ex: "Ponto da carne", "Adicionais")
class CustomizationGroup {
  final int? id;
  final String name;
  final int minSelections;
  final int maxSelections;
  final List<CustomizationOption> options;

  CustomizationGroup({
    this.id,
    required this.name,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  bool get required => minSelections > 0;

  /// Regra em texto para o cliente e o dono (ex: "Obrigatório · escolha 1")
  String get ruleLabel {
    final prefix = required ? 'Obrigatório' : 'Opcional';
    if (minSelections == maxSelections) return '$prefix · escolha $maxSelections';
    if (minSelections == 0) return '$prefix · até $maxSelections';
    return '$prefix · de $minSelections a $maxSelections';
  }

  factory CustomizationGroup.fromJson(Map<String, dynamic> json) => CustomizationGroup(
        id: json['id'],
        name: json['name'] ?? '',
        minSelections: json['minSelections'] ?? 0,
        maxSelections: json['maxSelections'] ?? 1,
        options: (json['options'] as List? ?? []).map((e) => CustomizationOption.fromJson(e)).toList(),
      );

  Map<String, dynamic> toRequestJson() => {
        'name': name,
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        'options': options.map((o) => o.toRequestJson()).toList(),
      };
}

class CustomizationOption {
  final int? id;
  final String name;
  final double priceModifier;
  final bool available;

  CustomizationOption({this.id, required this.name, required this.priceModifier, this.available = true});

  factory CustomizationOption.fromJson(Map<String, dynamic> json) => CustomizationOption(
        id: json['id'],
        name: json['name'] ?? '',
        priceModifier: _money(json['priceModifier']),
        available: json['available'] ?? true,
      );

  Map<String, dynamic> toRequestJson() => {
        if (id != null) 'id': id,
        'name': name,
        'priceModifier': priceModifier,
        'available': available,
      };
}

class Combo {
  final int id;
  final int? sectionId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool available;
  final bool active;
  final List<ComboItem> items;
  final double originalPrice;
  final double savings;

  Combo({
    required this.id,
    this.sectionId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.available,
    required this.active,
    required this.items,
    required this.originalPrice,
    required this.savings,
  });

  String get itemsSummary => items.map((i) => i.quantity > 1 ? '${i.quantity}x ${i.productName}' : i.productName).join(' + ');

  factory Combo.fromJson(Map<String, dynamic> json) => Combo(
        id: json['id'],
        sectionId: json['sectionId'],
        name: json['name'] ?? '',
        description: json['description'],
        price: _money(json['price']),
        imageUrl: json['imageUrl'],
        available: json['available'] ?? true,
        active: json['active'] ?? true,
        items: (json['items'] as List? ?? []).map((e) => ComboItem.fromJson(e)).toList(),
        originalPrice: _money(json['originalPrice']),
        savings: _money(json['savings']),
      );
}

class ComboItem {
  final int productId;
  final String productName;
  final int quantity;

  ComboItem({required this.productId, required this.productName, required this.quantity});

  factory ComboItem.fromJson(Map<String, dynamic> json) => ComboItem(
        productId: json['productId'],
        productName: json['productName'] ?? '',
        quantity: json['quantity'] ?? 1,
      );
}
