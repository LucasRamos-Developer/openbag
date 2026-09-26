import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../services/cart_service.dart';
import '../../utils/formatters.dart';
import 'customization_selector.dart';
import 'menu_image.dart';
import 'price_text.dart';

/// Abre o detalhe de um item (com complementos) ou de um combo.
/// Retorna a linha pronta para o carrinho, ou null se o cliente fechar.
Future<CartLine?> showItemDetailSheet(BuildContext context, {MenuItem? item, Combo? combo, bool canOrder = true}) {
  assert((item == null) != (combo == null));
  return showModalBottomSheet<CartLine>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _ItemDetailSheet(item: item, combo: combo, canOrder: canOrder),
  );
}

class _ItemDetailSheet extends StatefulWidget {
  final MenuItem? item;
  final Combo? combo;
  final bool canOrder;

  const _ItemDetailSheet({this.item, this.combo, required this.canOrder});

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  final _notes = TextEditingController();
  late final Map<int, Set<int>> _selected = {
    for (final g in widget.item?.customizationGroups ?? const <CustomizationGroup>[]) g.id!: <int>{},
  };
  int _quantity = 1;

  List<CustomizationGroup> get _groups => widget.item?.customizationGroups ?? const [];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<CartOption> get _chosenOptions => [
        for (final group in _groups)
          for (final option in group.options)
            if (_selected[group.id]!.contains(option.id))
              CartOption(id: option.id!, groupName: group.name, name: option.name, price: option.priceModifier),
      ];

  double get _unitPrice =>
      (widget.item != null ? widget.item!.currentPrice : widget.combo!.price) +
      _chosenOptions.fold(0.0, (sum, o) => sum + o.price);

  /// Grupos obrigatórios que ainda faltam
  List<String> get _missingGroups =>
      [for (final g in _groups) if (_selected[g.id]!.length < g.minSelections) g.name];

  void _add() {
    final notes = _notes.text.trim();
    final item = widget.item;
    final combo = widget.combo;
    Navigator.of(context).pop(CartLine(
      productId: item?.id,
      comboId: combo?.id,
      name: item != null ? item.name : combo!.name,
      imageUrl: item != null ? item.imageUrl : combo!.imageUrl,
      unitPrice: _unitPrice,
      quantity: _quantity,
      notes: notes.isEmpty ? null : notes,
      options: _chosenOptions,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final item = widget.item;
    final combo = widget.combo;
    final missing = _missingGroups;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                if ((item?.imageUrl ?? combo?.imageUrl) != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(child: MenuImage(imageUrl: item?.imageUrl ?? combo?.imageUrl, size: 220)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item?.name ?? combo!.name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      if ((item?.description ?? combo?.description) != null) ...[
                        const SizedBox(height: 6),
                        Text(item?.description ?? combo!.description!, style: TextStyle(color: muted)),
                      ],
                      if (combo != null) ...[
                        const SizedBox(height: 6),
                        Text('Inclui: ${combo.itemsSummary}', style: TextStyle(color: muted)),
                      ],
                      const SizedBox(height: 10),
                      if (item != null)
                        PriceText(price: item.price, promotionalPrice: item.promotionalPrice)
                      else
                        PriceText(
                          price: combo!.originalPrice > combo.price ? combo.originalPrice : combo.price,
                          promotionalPrice: combo.originalPrice > combo.price ? combo.price : null,
                        ),
                    ],
                  ),
                ),
                for (final group in _groups)
                  CustomizationSelector(
                    group: group,
                    selected: _selected[group.id]!,
                    onChanged: (value) => setState(() => _selected[group.id!] = value),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: AppTextField(
                    controller: _notes,
                    labelText: 'Alguma observação?',
                    hintText: 'Ex: sem cebola, maionese à parte',
                    variant: TextFieldVariant.filled,
                    maxLines: 2,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  AppQuantityStepper(value: _quantity, onChanged: (v) => setState(() => _quantity = v)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: !widget.canOrder
                          ? 'Restaurante fechado'
                          : missing.isNotEmpty
                              ? 'Escolha: ${missing.first}'
                              : 'Adicionar  ·  ${formatMoney(_unitPrice * _quantity)}',
                      fullWidth: true,
                      size: ButtonSize.large,
                      onPressed: widget.canOrder && missing.isEmpty ? _add : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
