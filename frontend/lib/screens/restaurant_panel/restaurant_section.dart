import 'package:flutter/material.dart';
import '../../widgets/navigation/panel_routes.dart';

/// Seções do painel do restaurante (`/restaurante/<slug>`)
enum RestaurantSection implements PanelSection {
  orders('pedidos', 'Pedidos', Icons.receipt_long_outlined, Icons.receipt_long),
  routes('rotas', 'Rotas', Icons.alt_route_outlined, Icons.alt_route),
  menu('cardapio', 'Cardápio', Icons.restaurant_menu_outlined, Icons.restaurant_menu),
  couriers('entregadores', 'Entregadores', Icons.two_wheeler_outlined, Icons.two_wheeler),
  cash('caixa', 'Caixa', Icons.point_of_sale_outlined, Icons.point_of_sale),
  reviews('avaliacoes', 'Avaliações', Icons.star_outline_rounded, Icons.star_rounded),
  store('loja', 'Loja', Icons.storefront_outlined, Icons.storefront);

  @override
  final String slug;
  @override
  final String label;
  @override
  final IconData icon;
  @override
  final IconData selectedIcon;

  const RestaurantSection(this.slug, this.label, this.icon, this.selectedIcon);

  @override
  List<String> get tabs => this == store ? [for (final t in StoreSection.values) t.slug] : const [];

  String get path => '/restaurante/$slug';
}

/// Abas da seção Loja (`/restaurante/loja/<slug>`)
enum StoreSection {
  general('geral', 'Geral', Icons.info_outline_rounded),
  appearance('aparencia', 'Aparência', Icons.palette_outlined),
  address('endereco', 'Endereço', Icons.place_outlined),
  hours('horarios', 'Horários', Icons.schedule_rounded),
  delivery('entrega', 'Pedidos e entrega', Icons.delivery_dining_outlined);

  final String slug;
  final String label;
  final IconData icon;

  const StoreSection(this.slug, this.label, this.icon);

  static StoreSection fromSlug(String? slug) => values.where((s) => s.slug == slug).firstOrNull ?? general;

  String get path => '${RestaurantSection.store.path}/$slug';
}
