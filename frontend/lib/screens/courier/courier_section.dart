import 'package:flutter/material.dart';
import '../../widgets/navigation/panel_routes.dart';

/// Seções do painel do entregador (`/entregador/<slug>`)
enum CourierSection implements PanelSection {
  work('trabalhar', 'Trabalhar', Icons.bolt_outlined, Icons.bolt),
  earnings('ganhos', 'Ganhos', Icons.payments_outlined, Icons.payments),
  association('associacao', 'Associação', Icons.groups_outlined, Icons.groups),
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
  List<String> get tabs => this == association ? [for (final t in MemberAreaTab.values) t.slug] : const [];

  String get path => '/entregador/$slug';
}

/// Sub-abas da área do cooperado (`/entregador/associacao/<aba>`)
enum MemberAreaTab {
  home('resumo', 'Resumo', Icons.home_outlined),
  announcements('comunicados', 'Comunicados', Icons.campaign_outlined),
  invoices('faturas', 'Faturas', Icons.receipt_long_outlined),
  benefits('convenios', 'Convênios', Icons.handshake_outlined),
  polls('enquetes', 'Enquetes', Icons.how_to_vote_outlined),
  documents('documentos', 'Documentos', Icons.folder_outlined);

  final String slug;
  final String label;
  final IconData icon;
  const MemberAreaTab(this.slug, this.label, this.icon);

  static MemberAreaTab fromSlug(String? slug) => values.where((t) => t.slug == slug).firstOrNull ?? home;

  String get path => '${CourierSection.association.path}/$slug';
}
