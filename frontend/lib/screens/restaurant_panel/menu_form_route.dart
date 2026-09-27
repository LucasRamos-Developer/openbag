import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../services/restaurant_panel_service.dart';
import 'combo_form_screen.dart';
import 'menu_item_form_screen.dart';
import 'restaurant_section.dart';

/// Tipo de formulário do cardápio no endereço (`/restaurante/cardapio/<tipo>/<id|novo>`)
enum MenuFormKind {
  item('itens'),
  combo('combos');

  final String slug;

  const MenuFormKind(this.slug);

  static MenuFormKind? fromSlug(String? slug) => values.where((k) => k.slug == slug).firstOrNull;

  /// Endereço do formulário; [id] nulo = novo
  String path({int? id, int? sectionId}) => Uri(
        path: '${RestaurantSection.menu.path}/$slug/${id ?? 'novo'}',
        queryParameters: sectionId == null ? null : {'secao': '$sectionId'},
      ).toString();
}

/// Fecha o formulário: volta para a tela anterior ou, se ele foi aberto direto pelo endereço, para o cardápio
void closeMenuForm(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(RestaurantSection.menu.path);

/// Abre o formulário de item ou combo pelo endereço. Carrega o cardápio quando a página
/// foi aberta direto (sem passar pelo painel).
class MenuFormRoute extends StatefulWidget {
  final MenuFormKind kind;

  /// Nulo = novo
  final int? id;
  final int? sectionId;

  const MenuFormRoute({super.key, required this.kind, this.id, this.sectionId});

  @override
  State<MenuFormRoute> createState() => _MenuFormRouteState();
}

class _MenuFormRouteState extends State<MenuFormRoute> {
  @override
  void initState() {
    super.initState();
    final service = context.read<RestaurantPanelService>();
    if (service.menu == null && !service.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => service.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantPanelService>();
    final menu = service.menu;

    if (menu == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => closeMenuForm(context))),
        body: service.error == null
            ? const Center(child: CircularProgressIndicator())
            : AppEmptyState(
                icon: Icons.cloud_off_outlined,
                message: service.error!,
                actionLabel: 'Tentar novamente',
                onAction: service.load,
              ),
      );
    }

    final id = widget.id;
    switch (widget.kind) {
      case MenuFormKind.item:
        final item = id == null ? null : menu.allItems.where((i) => i.id == id).firstOrNull;
        if (id != null && item == null) return _notFound(context, 'Item não encontrado no cardápio.');
        return MenuItemFormScreen(key: ValueKey('item-$id'), item: item, initialSectionId: widget.sectionId);
      case MenuFormKind.combo:
        final combo = id == null ? null : menu.allCombos.where((c) => c.id == id).firstOrNull;
        if (id != null && combo == null) return _notFound(context, 'Combo não encontrado no cardápio.');
        return ComboFormScreen(key: ValueKey('combo-$id'), combo: combo, initialSectionId: widget.sectionId);
    }
  }

  Widget _notFound(BuildContext context, String message) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => closeMenuForm(context))),
        body: AppEmptyState(
          icon: Icons.search_off_rounded,
          message: message,
          actionLabel: 'Voltar ao cardápio',
          onAction: () => context.go(RestaurantSection.menu.path),
        ),
      );
}
