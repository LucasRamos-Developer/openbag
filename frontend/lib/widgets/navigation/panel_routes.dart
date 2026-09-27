import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/ui.dart';

/// Seção do menu de um painel, com endereço próprio (`/restaurante/pedidos`).
/// Implementada pelos enums de seção de cada painel.
abstract interface class PanelSection {
  /// Trecho da URL da seção
  String get slug;
  String get label;
  IconData get icon;
  IconData get selectedIcon;

  /// Sub-abas da seção (`/restaurante/loja/geral`); a primeira é a padrão. Vazia = sem sub-abas
  List<String> get tabs;
}

extension PanelSectionDestination on PanelSection {
  AppPanelDestination destination({int badge = 0}) =>
      AppPanelDestination(icon: icon, selectedIcon: selectedIcon, label: label, badge: badge);
}

/// Rotas de um painel: `/base` leva à primeira seção e `/base/:secao[/:aba]` montam o painel.
///
/// Todas as seções usam a mesma chave de página, então trocar de seção (inclusive pelo voltar do
/// navegador) só atualiza o painel: o estado, os dados carregados e as conexões em tempo real continuam.
/// Endereços desconhecidos levam à primeira seção; seção com sub-abas sem aba leva à primeira aba.
///
/// Rotas mais específicas (ex: `/restaurante/cozinha`) devem ser declaradas antes destas.
List<GoRoute> panelRoutes<S extends PanelSection>({
  required String base,
  required List<S> sections,
  required Widget Function(S section, String? tab) builder,
}) {
  S? find(String? slug) => sections.where((s) => s.slug == slug).firstOrNull;
  String pathOf(S section) => section.tabs.isEmpty ? '$base/${section.slug}' : '$base/${section.slug}/${section.tabs.first}';

  Page<void> page(Widget child) => NoTransitionPage(key: ValueKey(base), child: child);

  return [
    GoRoute(path: base, redirect: (_, __) => pathOf(sections.first)),
    GoRoute(
      path: '$base/:secao',
      redirect: (_, state) {
        final section = find(state.pathParameters['secao']);
        if (section == null) return pathOf(sections.first);
        return section.tabs.isEmpty ? null : pathOf(section);
      },
      pageBuilder: (_, state) => page(builder(find(state.pathParameters['secao'])!, null)),
    ),
    GoRoute(
      path: '$base/:secao/:aba',
      redirect: (_, state) {
        final section = find(state.pathParameters['secao']);
        if (section == null) return pathOf(sections.first);
        return section.tabs.contains(state.pathParameters['aba']) ? null : pathOf(section);
      },
      pageBuilder: (_, state) =>
          page(builder(find(state.pathParameters['secao'])!, state.pathParameters['aba'])),
    ),
  ];
}
