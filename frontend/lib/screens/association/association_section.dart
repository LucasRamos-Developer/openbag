import 'package:flutter/material.dart';
import '../../widgets/navigation/panel_routes.dart';

/// Seções do painel da associação (`/associacao/<slug>`)
enum AssociationSection implements PanelSection {
  overview('visao-geral', 'Visão geral', Icons.dashboard_outlined, Icons.dashboard),
  members('associados', 'Associados', Icons.groups_outlined, Icons.groups),
  invites('convites', 'Convites', Icons.confirmation_number_outlined, Icons.confirmation_number),
  partners('lojas', 'Lojas parceiras', Icons.storefront_outlined, Icons.storefront),
  deliveries('entregas', 'Tabela de entrega', Icons.local_shipping_outlined, Icons.local_shipping),
  finance('financeiro', 'Financeiro', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
  benefits('convenios', 'Convênios', Icons.handshake_outlined, Icons.handshake),
  community('assembleia', 'Assembleia', Icons.how_to_vote_outlined, Icons.how_to_vote),
  reports('relatorios', 'Relatórios', Icons.insights_outlined, Icons.insights),
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
  List<String> get tabs => switch (this) {
        finance => [for (final t in FinanceTab.values) t.slug],
        community => [for (final t in CommunityTab.values) t.slug],
        _ => const [],
      };

  String get path => '/associacao/$slug';
}

/// Sub-abas do Financeiro (`/associacao/financeiro/<aba>`)
enum FinanceTab {
  summary('resumo', 'Resumo', Icons.space_dashboard_outlined),
  invoices('faturas', 'Faturas', Icons.receipt_long_outlined),
  ledger('lancamentos', 'Lançamentos', Icons.swap_vert),
  fund('caixinha', 'Caixinha', Icons.volunteer_activism_outlined),
  billing('cobranca', 'Cobrança', Icons.tune);

  final String slug;
  final String label;
  final IconData icon;
  const FinanceTab(this.slug, this.label, this.icon);

  static FinanceTab fromSlug(String? slug) => values.where((t) => t.slug == slug).firstOrNull ?? summary;

  String get path => '${AssociationSection.finance.path}/$slug';
}

/// Sub-abas da Assembleia (`/associacao/assembleia/<aba>`)
enum CommunityTab {
  announcements('comunicados', 'Comunicados', Icons.campaign_outlined),
  polls('enquetes', 'Enquetes', Icons.poll_outlined),
  documents('documentos', 'Atas e documentos', Icons.folder_outlined);

  final String slug;
  final String label;
  final IconData icon;
  const CommunityTab(this.slug, this.label, this.icon);

  static CommunityTab fromSlug(String? slug) => values.where((t) => t.slug == slug).firstOrNull ?? announcements;

  String get path => '${AssociationSection.community.path}/$slug';
}
