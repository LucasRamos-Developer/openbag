import 'package:flutter/material.dart';

/// Catálogo de ícones das seções do cardápio. A chave é gravada no backend (MenuSection.icon).
class MenuSectionIcons {
  MenuSectionIcons._();

  static const String fallbackKey = 'restaurant_menu';

  static const Map<String, ({IconData icon, String label})> catalog = {
    'lunch_dining': (icon: Icons.lunch_dining_outlined, label: 'Lanches'),
    'local_pizza': (icon: Icons.local_pizza_outlined, label: 'Pizzas'),
    'local_drink': (icon: Icons.local_drink_outlined, label: 'Bebidas'),
    'liquor': (icon: Icons.liquor_outlined, label: 'Drinks'),
    'coffee': (icon: Icons.coffee_outlined, label: 'Cafés'),
    'tapas': (icon: Icons.tapas_outlined, label: 'Porções'),
    'fastfood': (icon: Icons.fastfood_outlined, label: 'Combos'),
    'dinner_dining': (icon: Icons.dinner_dining_outlined, label: 'Massas'),
    'rice_bowl': (icon: Icons.rice_bowl_outlined, label: 'Pratos'),
    'set_meal': (icon: Icons.set_meal_outlined, label: 'Peixes e japonês'),
    'kebab_dining': (icon: Icons.kebab_dining_outlined, label: 'Espetos'),
    'ramen_dining': (icon: Icons.ramen_dining_outlined, label: 'Sopas'),
    'eco': (icon: Icons.eco_outlined, label: 'Saudáveis'),
    'bakery_dining': (icon: Icons.bakery_dining_outlined, label: 'Padaria'),
    'breakfast_dining': (icon: Icons.breakfast_dining_outlined, label: 'Café da manhã'),
    'icecream': (icon: Icons.icecream_outlined, label: 'Sorvetes'),
    'cake': (icon: Icons.cake_outlined, label: 'Sobremesas'),
    'local_offer': (icon: Icons.local_offer_outlined, label: 'Promoções'),
    fallbackKey: (icon: Icons.restaurant_menu, label: 'Geral'),
  };

  static IconData of(String? key) => (catalog[key] ?? catalog[fallbackKey]!).icon;

  /// Sugere um ícone pelo nome da seção (ex: "Bebidas geladas" → local_drink)
  static String suggest(String sectionName) {
    final name = _plain(sectionName);
    for (final rule in _rules) {
      if (rule.words.any(name.contains)) return rule.key;
    }
    return fallbackKey;
  }

  static const _rules = [
    (key: 'fastfood', words: ['combo', 'kit']),
    (key: 'local_pizza', words: ['pizza', 'esfiha', 'esfirra']),
    (key: 'lunch_dining', words: ['lanche', 'burger', 'hamburguer', 'sanduiche', 'x-', 'smash']),
    (key: 'liquor', words: ['cerveja', 'drink', 'chope', 'vinho', 'alcool']),
    (key: 'breakfast_dining', words: ['cafe da manha', 'manha', 'brunch']),
    (key: 'coffee', words: ['cafe', 'cafeteria', 'capuccino', 'cappuccino']),
    (key: 'local_drink', words: ['bebida', 'suco', 'refri', 'agua', 'refrigerante']),
    (key: 'tapas', words: ['porcao', 'porcoes', 'petisco', 'entrada', 'batata', 'acompanhamento']),
    (key: 'dinner_dining', words: ['massa', 'macarrao', 'lasanha', 'espaguete']),
    (key: 'set_meal', words: ['peixe', 'sushi', 'japon', 'temaki', 'frutos do mar']),
    (key: 'kebab_dining', words: ['espeto', 'churrasco', 'grelhado', 'carne']),
    (key: 'ramen_dining', words: ['sopa', 'caldo', 'ramen']),
    (key: 'eco', words: ['salada', 'saudavel', 'vegano', 'vegetariano', 'fit', 'bowl']),
    (key: 'bakery_dining', words: ['padaria', 'pao', 'paes', 'salgado']),
    (key: 'icecream', words: ['sorvete', 'gelato', 'acai', 'milkshake']),
    (key: 'cake', words: ['sobremesa', 'doce', 'bolo', 'torta']),
    (key: 'local_offer', words: ['promo', 'oferta', 'desconto']),
    (key: 'rice_bowl', words: ['prato', 'executivo', 'marmita', 'refeicao', 'almoco']),
  ];

  static String _plain(String text) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }
}
