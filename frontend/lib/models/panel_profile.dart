import 'package:flutter/material.dart';
import 'user.dart';

/// Perfil de uso do app: cada role de gestão tem um painel; todo usuário também é cliente
class PanelProfile {
  /// Role exigida (null = qualquer usuário)
  final String? role;
  final String label;
  final IconData icon;
  final String route;

  const PanelProfile({required this.role, required this.label, required this.icon, required this.route});

  static const admin = PanelProfile(
    role: UserRoles.admin,
    label: 'Administração',
    icon: Icons.admin_panel_settings_outlined,
    route: '/admin/associacoes',
  );
  static const association = PanelProfile(
    role: UserRoles.associationManager,
    label: 'Cooperativa',
    icon: Icons.groups_outlined,
    route: '/associacao',
  );
  static const restaurant = PanelProfile(
    role: UserRoles.restaurantOwner,
    label: 'Restaurante',
    icon: Icons.storefront_outlined,
    route: '/restaurante',
  );
  static const courier = PanelProfile(
    role: UserRoles.deliveryPerson,
    label: 'Entregador',
    icon: Icons.two_wheeler_outlined,
    route: '/entregador',
  );
  static const customer = PanelProfile(
    role: null,
    label: 'Cliente',
    icon: Icons.shopping_bag_outlined,
    route: '/home',
  );

  /// Em ordem de prioridade: o primeiro perfil do usuário é a tela inicial após o login
  static const all = [admin, association, restaurant, courier, customer];

  static List<PanelProfile> of(User user) => all.where((p) => p.role == null || user.hasRole(p.role!)).toList();

  bool get isPanel => role != null;
}
