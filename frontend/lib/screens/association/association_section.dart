import 'package:flutter/material.dart';
import '../../widgets/navigation/panel_routes.dart';

/// Seções do painel da associação (`/associacao/<slug>`)
enum AssociationSection implements PanelSection {
  overview('visao-geral', 'Visão geral', Icons.dashboard_outlined, Icons.dashboard),
  members('associados', 'Associados', Icons.groups_outlined, Icons.groups),
  invites('convites', 'Convites', Icons.confirmation_number_outlined, Icons.confirmation_number),
  deliveries('entregas', 'Entregas', Icons.local_shipping_outlined, Icons.local_shipping),
  profile('dados', 'Dados', Icons.apartment_outlined, Icons.apartment);

  @override
  final String slug;
  @override
  final String label;
  @override
  final IconData icon;
  @override
  final IconData selectedIcon;

  const AssociationSection(this.slug, this.label, this.icon, this.selectedIcon);

  @override
  List<String> get tabs => const [];

  String get path => '/associacao/$slug';
}
