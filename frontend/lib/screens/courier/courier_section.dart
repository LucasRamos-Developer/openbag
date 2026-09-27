import 'package:flutter/material.dart';
import '../../widgets/navigation/panel_routes.dart';

/// Seções do painel do entregador (`/entregador/<slug>`)
enum CourierSection implements PanelSection {
  work('trabalhar', 'Trabalhar', Icons.bolt_outlined, Icons.bolt),
  earnings('ganhos', 'Ganhos', Icons.payments_outlined, Icons.payments),
  stores('lojas', 'Lojas', Icons.storefront_outlined, Icons.storefront),
  vehicles('veiculos', 'Veículos', Icons.two_wheeler_outlined, Icons.two_wheeler),
  profile('perfil', 'Perfil', Icons.person_outline, Icons.person),
  badge('placa', 'Placa', Icons.qr_code_2_outlined, Icons.qr_code_2);

  @override
  final String slug;
  @override
  final String label;
  @override
  final IconData icon;
  @override
  final IconData selectedIcon;

  const CourierSection(this.slug, this.label, this.icon, this.selectedIcon);

  @override
  List<String> get tabs => const [];

  String get path => '/entregador/$slug';
}
