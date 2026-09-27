import 'package:flutter/material.dart';
import '../../widgets/navigation/panel_routes.dart';

/// Seções do painel do super admin (`/admin/<slug>`); tudo somente leitura, exceto a moderação de associações
enum AdminSection implements PanelSection {
  overview('visao-geral', 'Visão geral', Icons.dashboard_outlined, Icons.dashboard),
  restaurants('restaurantes', 'Restaurantes', Icons.storefront_outlined, Icons.storefront),
  associations('associacoes', 'Associações', Icons.apartment_outlined, Icons.apartment),
  couriers('entregadores', 'Entregadores', Icons.two_wheeler_outlined, Icons.two_wheeler),
  users('usuarios', 'Usuários', Icons.people_outline, Icons.people),
  orders('pedidos', 'Pedidos', Icons.receipt_long_outlined, Icons.receipt_long);

  @override
  final String slug;
  @override
  final String label;
  @override
  final IconData icon;
  @override
  final IconData selectedIcon;

  const AdminSection(this.slug, this.label, this.icon, this.selectedIcon);

  @override
  List<String> get tabs => const [];

  String get path => '/admin/$slug';
}
