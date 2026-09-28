import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../services/cart_service.dart';
import 'item_detail_sheet.dart';
import 'menu_item_tile.dart';

/// Cardápio com busca para montar um pedido (ex: pedido do balcão no painel da loja).
///
/// Mostra só o que pode ser vendido agora (visível, disponível e em seção visível). Item com complementos
/// abre o detalhe para escolher; item simples e combo entram direto com quantidade 1.
class MenuPicker extends StatefulWidget {
  final Menu menu;
  final ValueChanged<CartLine> onPick;

  /// Padding da lista (a busca acompanha as laterais)
  final EdgeInsets padding;

  const MenuPicker({super.key, required this.menu, required this.onPick, this.padding = const EdgeInsets.all(16)});

  @override
  State<MenuPicker> createState() => _MenuPickerState();
}

class _MenuPickerState extends State<MenuPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String name, String? description) {
    final query = _search.text.trim().toLowerCase();
    return query.isEmpty || name.toLowerCase().contains(query) || (description?.toLowerCase().contains(query) ?? false);
  }

  Future<void> _pickItem(MenuItem item) async {
    if (item.customizationGroups.isEmpty) {
      widget.onPick(CartLine(productId: item.id, name: item.name, imageUrl: item.imageUrl, unitPrice: item.currentPrice, quantity: 1));
      return;
    }
    final line = await showItemDetailSheet(context, item: item);
    if (line != null) widget.onPick(line);
  }

  void _pickCombo(Combo combo) =>
      widget.onPick(CartLine(comboId: combo.id, name: combo.name, imageUrl: combo.imageUrl, unitPrice: combo.price, quantity: 1));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sections = [
      for (final section in widget.menu.sections)
        if (section.active)
          (
            section: section,
            items: section.items.where((i) => i.active && i.available && _matches(i.name, i.description)).toList(),
            combos: section.combos.where((c) => c.active && c.available && _matches(c.name, c.description)).toList(),
          ),
    ].where((s) => s.items.isNotEmpty || s.combos.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(widget.padding.left, widget.padding.top, widget.padding.right, 8),
          child: AppSearchBar(controller: _search, hintText: 'Buscar no cardápio', onChanged: (_) => setState(() {})),
        ),
        Expanded(
          child: sections.isEmpty
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  message: _search.text.trim().isEmpty ? 'Nenhum item disponível no cardápio.' : 'Nada encontrado.',
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(widget.padding.left, 0, widget.padding.right, widget.padding.bottom),
                  children: [
                    for (final entry in sections) ...[
                      AppSectionHeader(title: entry.section.name, padding: const EdgeInsets.only(top: 16, bottom: 4)),
                      for (final item in entry.items)
                        MenuItemTile(
                          key: ValueKey('item-${item.id}'),
                          name: item.name,
                          description: item.description,
                          price: item.price,
                          promotionalPrice: item.promotionalPrice,
                          imageUrl: item.imageUrl,
                          subtitle: item.customizationGroups.isEmpty ? null : 'Com complementos',
                          trailing: Icon(Icons.add_circle_outline, color: colors.primaryText),
                          onTap: () => _pickItem(item),
                        ),
                      for (final combo in entry.combos)
                        MenuItemTile(
                          key: ValueKey('combo-${combo.id}'),
                          name: combo.name,
                          description: combo.description,
                          price: combo.price,
                          imageUrl: combo.imageUrl,
                          subtitle: combo.itemsSummary,
                          trailing: Icon(Icons.add_circle_outline, color: colors.primaryText),
                          onTap: () => _pickCombo(combo),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Abre o [MenuPicker] em tela cheia (celular) e devolve a linha escolhida
Future<CartLine?> showMenuPickerPage(BuildContext context, {required Menu menu}) {
  return Navigator.of(context).push<CartLine>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (pageContext) => Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Fechar', icon: const Icon(Icons.close), onPressed: () => Navigator.of(pageContext).pop()),
        titleSpacing: 0,
        title: const Text('Adicionar item'),
      ),
      body: MenuPicker(menu: menu, onPick: (line) => Navigator.of(pageContext).pop(line)),
    ),
  ));
}
